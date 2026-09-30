#!/usr/bin/env python3
"""문제 시드 데이터(PsyKNLE/PsyKNLEApp.swift)의 무결성을 검사한다.

Xcode 없이도 돌 수 있는 검사만 모아 두었다. Set<Question>은 id가 같으면
조용히 하나로 합쳐지고, 잘못된 answer/classifi/year는 빌드는 되지만 앱에서
문항이 사라지거나 필터에서 빠지기 때문에 컴파일만으로는 잡히지 않는다.

사용법: python3 Scripts/validate_questions.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
APP_FILE = REPO_ROOT / "PsyKNLE" / "PsyKNLEApp.swift"
QUESTION_VIEW_FILE = REPO_ROOT / "PsyKNLE" / "QuestionView.swift"
TOPICS_FILE = REPO_ROOT / "PsyKNLE" / "StudyTopics.swift"

# 간호과정 단계. QuestionView.swift의 listDxOrTx와 같아야 한다.
VALID_CLASSIFI = {"사정", "진단", "계획", "중재", "평가"}
YEAR_PATTERN = re.compile(r"^(\d{4})(?:-([1-9]\d*))?$")
# "2026-71": 연도-문항번호. 정신간호학은 2교시 71~105번이다.
ID_PATTERN = re.compile(r"^(\d{4})-(\d+)$")
QUESTION_RANGE = range(71, 106)

STRING_FIELDS = ("id", "year", "intro", "main", "classifi", "topic")
ARRAY_FIELDS = ("answer", "subject", "choice")


class ParseError(Exception):
    pass


def scan(src: str, start: int, stop: int | None = None):
    """문자열·주석을 건너뛰며 (index, char, line)을 내놓는다."""
    i = start
    end = len(src) if stop is None else stop
    line = src.count("\n", 0, start) + 1
    while i < end:
        c = src[i]
        if c == "\n":
            line += 1
            i += 1
            continue
        if c == '"':
            i, line = skip_string(src, i, line)
            continue
        if src.startswith("//", i):
            while i < end and src[i] != "\n":
                i += 1
            continue
        if src.startswith("/*", i):
            i, line = skip_block_comment(src, i, line)
            continue
        yield i, c, line
        i += 1


def skip_string(src: str, i: int, line: int) -> tuple[int, int]:
    """여는 따옴표 위치에서 시작해 닫는 따옴표 다음 위치를 돌려준다."""
    i += 1
    while i < len(src):
        if src[i] == "\\":
            i += 2
            continue
        if src[i] == '"':
            return i + 1, line
        if src[i] == "\n":
            line += 1
        i += 1
    raise ParseError(f"{line}행: 닫히지 않은 문자열 리터럴")


def skip_block_comment(src: str, i: int, line: int) -> tuple[int, int]:
    depth = 1
    i += 2
    while i < len(src) and depth > 0:
        if src.startswith("/*", i):
            depth += 1
            i += 2
            continue
        if src.startswith("*/", i):
            depth -= 1
            i += 2
            continue
        if src[i] == "\n":
            line += 1
        i += 1
    if depth:
        raise ParseError(f"{line}행: 닫히지 않은 블록 주석")
    return i, line


def read_string_literal(src: str, i: int) -> tuple[str, int]:
    """여는 따옴표 위치에서 (해석된 문자열, 닫는 따옴표 다음 위치)."""
    out: list[str] = []
    i += 1
    escapes = {"n": "\n", "t": "\t", '"': '"', "\\": "\\", "0": "\0", "r": "\r"}
    while i < len(src):
        c = src[i]
        if c == "\\":
            out.append(escapes.get(src[i + 1], src[i + 1]))
            i += 2
            continue
        if c == '"':
            return "".join(out), i + 1
        out.append(c)
        i += 1
    raise ParseError("닫히지 않은 문자열 리터럴")


def find_active_seed_region(src: str) -> tuple[int, int]:
    """주석 밖에 있는 `let items: Set<Question> = [` 의 여닫는 대괄호 구간."""
    marker = re.compile(r"let\s+items\s*:\s*Set<Question>\s*=\s*\[")
    for i, c, _ in scan(src, 0):
        if c != "l":
            continue
        m = marker.match(src, i)
        if not m:
            continue
        open_bracket = m.end() - 1
        depth = 0
        for j, cj, _ in scan(src, open_bracket):
            if cj in "([{":
                depth += 1
            elif cj in ")]}":
                depth -= 1
                if depth == 0:
                    return open_bracket + 1, j
        raise ParseError("시드 배열의 닫는 대괄호를 찾지 못했다")
    raise ParseError("활성 `let items: Set<Question> = [` 선언을 찾지 못했다")


def split_top_level(src: str, start: int, stop: int) -> list[tuple[int, int, int]]:
    """depth 0의 콤마로 구간을 나눈다. (시작, 끝, 시작 행) 목록."""
    parts = []
    depth = 0
    seg_start = start
    seg_line = src.count("\n", 0, start) + 1
    for i, c, line in scan(src, start, stop):
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            parts.append((seg_start, i, seg_line))
            seg_start = i + 1
            seg_line = line
    parts.append((seg_start, stop, seg_line))
    return [p for p in parts if src[p[0] : p[1]].strip()]


def parse_arguments(src: str, start: int, stop: int) -> dict[str, tuple[str, int, int]]:
    """`label: value` 쌍을 {label: (value 원문, 값 시작 위치, 행)}으로."""
    args: dict[str, tuple[str, int, int]] = {}
    for seg_start, seg_end, seg_line in split_top_level(src, start, stop):
        text = src[seg_start:seg_end]
        m = re.match(r"\s*([A-Za-z_][A-Za-z0-9_]*)\s*:", text)
        if not m:
            continue
        label = m.group(1)
        value_start = seg_start + m.end()
        args[label] = (src[value_start:seg_end], value_start, seg_line)
    return args


def parse_string_array(src: str, start: int, stop: int) -> list[str]:
    values = []
    for seg_start, seg_end, _ in split_top_level(src, start, stop):
        text = src[seg_start:seg_end]
        offset = text.index('"') if '"' in text else None
        if offset is None:
            continue
        value, _ = read_string_literal(src, seg_start + offset)
        values.append(value)
    return values


def bracket_span(src: str, start: int, opener: str) -> tuple[int, int]:
    """start 이후 첫 opener의 내부 구간 (여는 괄호 다음, 닫는 괄호)."""
    depth = 0
    inner_start = None
    for i, c, _ in scan(src, start):
        if c in "([{":
            depth += 1
            if depth == 1:
                if c != opener:
                    raise ParseError(f"'{opener}'를 기대했으나 '{c}'를 만났다")
                inner_start = i + 1
        elif c in ")]}":
            depth -= 1
            if depth == 0:
                return inner_start, i
    raise ParseError("괄호가 닫히지 않았다")


def parse_questions(src: str) -> list[dict]:
    seed_start, seed_end = find_active_seed_region(src)
    questions = []
    for seg_start, seg_end, _ in split_top_level(src, seed_start, seed_end):
        text = src[seg_start:seg_end]
        m = re.search(r"\bQuestion\s*\(", text)
        if not m:
            continue
        args_start, args_end = bracket_span(src, seg_start + m.end() - 1, "(")
        args = parse_arguments(src, args_start, args_end)
        entry: dict = {"line": src.count("\n", 0, seg_start + m.start()) + 1}

        for field in STRING_FIELDS + ("comment1", "comment2"):
            if field not in args:
                continue
            raw, value_start, _ = args[field]
            if raw.lstrip().startswith('"'):
                entry[field], _ = read_string_literal(src, value_start + raw.index('"'))

        for field in ARRAY_FIELDS:
            if field not in args:
                continue
            _, value_start, _ = args[field]
            inner = bracket_span(src, value_start, "[")
            entry[field] = parse_string_array(src, *inner)

        if "q" in args:
            _, value_start, _ = args["q"]
            inner_start, inner_end = bracket_span(src, value_start, "[")
            options = []
            for o_start, o_end, _ in split_top_level(src, inner_start, inner_end):
                o_text = src[o_start:o_end]
                mo = re.search(r"\bQ\s*\(", o_text)
                if not mo:
                    continue
                o_args = parse_arguments(src, *bracket_span(src, o_start + mo.end() - 1, "("))
                option = {}
                for key in ("id", "q"):
                    if key in o_args:
                        raw, value_start, _ = o_args[key]
                        if raw.lstrip().startswith('"'):
                            option[key], _ = read_string_literal(src, value_start + raw.index('"'))
                options.append(option)
            entry["q"] = options

        entry["missing"] = [f for f in ("id", "year", "intro", "main", "classifi", "answer", "subject", "q") if f not in args]
        questions.append(entry)
    return questions


def parse_list_years(src: str) -> list[str]:
    m = re.search(r"let\s+listYears\s*:\s*\[String\]\s*=\s*\[(.*?)\]", src, re.S)
    if not m:
        raise ParseError("QuestionView.swift에서 listYears를 찾지 못했다")
    return re.findall(r'"([^"]*)"', m.group(1))


def parse_list_classifi(src: str) -> list[str]:
    m = re.search(r"let\s+listDxOrTx\s*:\s*\[String\]\s*=\s*\[(.*?)\]", src, re.S)
    if not m:
        raise ParseError("QuestionView.swift에서 listDxOrTx를 찾지 못했다")
    return re.findall(r'"([^"]*)"', m.group(1))


def parse_study_topics(src: str) -> list[str]:
    """StudyTopics.chapters 안의 주제 이름(단원 제목 제외)."""
    return re.findall(r'^\s+"([^"]+)",\s*$', src, re.M)


def main() -> int:
    errors: list[str] = []
    src = APP_FILE.read_text(encoding="utf-8")
    questions = parse_questions(src)

    def fail(entry: dict, message: str) -> None:
        errors.append(f"{APP_FILE.relative_to(REPO_ROOT)}:{entry['line']} [{entry.get('id', '?')}] {message}")

    if not questions:
        errors.append("활성 시드 배열에서 문항을 하나도 찾지 못했다")

    seen_ids: dict[str, int] = {}
    years: dict[str, int] = {}

    for entry in questions:
        for field in entry["missing"]:
            fail(entry, f"필수 인자 누락: {field}")

        qid = entry.get("id", "")
        if not qid:
            fail(entry, "id가 비어 있다")
        elif qid in seen_ids:
            fail(entry, f"id 중복 (앞서 {seen_ids[qid]}행에 있음). Set<Question>에서 한 문항이 조용히 사라진다")
        else:
            seen_ids[qid] = entry["line"]

        year = entry.get("year", "")
        ym = YEAR_PATTERN.match(year)
        if not ym:
            fail(entry, f'year 형식이 잘못됐다: "{year}" (예: "2025", "2026-2")')
        else:
            years[year] = years.get(year, 0) + 1
            im = ID_PATTERN.match(qid)
            if not im:
                fail(entry, f'id 형식이 잘못됐다: "{qid}" (예: "2026-71")')
            elif im.group(1) != ym.group(1):
                fail(entry, f'id와 year가 어긋난다: id "{qid}" vs year "{year}"')
            elif int(im.group(2)) not in QUESTION_RANGE:
                fail(entry, f'문항번호가 정신간호학 범위(71~105)를 벗어난다: "{qid}"')

        classifi = entry.get("classifi", "")
        if classifi not in VALID_CLASSIFI:
            fail(entry, f'classifi가 분류 필터에 없는 값이다: "{classifi}" (허용: {", ".join(sorted(VALID_CLASSIFI))})')

        for field in ("intro", "main"):
            if not entry.get(field, "").strip():
                fail(entry, f"{field}가 비어 있다")

        if not [s for s in entry.get("subject", []) if s.strip()]:
            fail(entry, "subject 키워드가 비어 있다. 키워드 검색에 걸리지 않는다")

        options = entry.get("q", [])
        option_ids = [o.get("id", "") for o in options]
        if len(options) < 2:
            fail(entry, f"보기가 {len(options)}개뿐이다")
        if len(set(option_ids)) != len(option_ids):
            fail(entry, f"보기 id가 중복된다: {option_ids}")
        for option in options:
            if not option.get("q", "").strip():
                fail(entry, f'보기 "{option.get("id", "?")}"의 내용이 비어 있다')

        answers = entry.get("answer", [])
        if not answers:
            fail(entry, "answer가 비어 있다")
        for a in answers:
            if a not in option_ids:
                fail(entry, f'answer "{a}"에 해당하는 보기가 없다 (보기 id: {option_ids})')
        if sorted(answers) != answers:
            fail(entry, f"answer는 오름차순이어야 채점이 맞는다: {answers}")

        if entry.get("choice"):
            fail(entry, "choice는 사용자 선택 기록이므로 시드에서는 비어 있어야 한다")

        if not entry.get("comment1", "").strip():
            fail(entry, "comment1(해설)이 비어 있다")

    # 연도 필터 목록이 데이터의 모든 연도를 담고 있는지 확인한다.
    list_years = parse_list_years(QUESTION_VIEW_FILE.read_text(encoding="utf-8"))
    for year in sorted(years):
        if year not in list_years:
            errors.append(
                f"{QUESTION_VIEW_FILE.relative_to(REPO_ROOT)}: listYears에 \"{year}\"가 없어 "
                f"해당 연도 {years[year]}문항을 연도별 필터로 고를 수 없다"
            )
    for year in list_years:
        if year != "전체" and year not in years:
            errors.append(
                f"{QUESTION_VIEW_FILE.relative_to(REPO_ROOT)}: listYears의 \"{year}\"에 해당하는 문항이 없다"
            )

    # 분류 필터 목록과 이 스크립트의 허용 분류가 어긋나면 필터로 고를 수 없는 문항이 생긴다.
    list_classifi = [c for c in parse_list_classifi(QUESTION_VIEW_FILE.read_text(encoding="utf-8")) if c != "전체"]
    if set(list_classifi) != VALID_CLASSIFI:
        errors.append(
            f"{QUESTION_VIEW_FILE.relative_to(REPO_ROOT)}: listDxOrTx {list_classifi}가 "
            f"허용 분류 {sorted(VALID_CLASSIFI)}와 다르다"
        )

    # 주제별 메뉴에 없는 주제는 필터로 고를 수 없고, 문항이 없는 주제는 빈 목록이 된다.
    study_topics = parse_study_topics(TOPICS_FILE.read_text(encoding="utf-8"))
    if len(study_topics) != len(set(study_topics)):
        errors.append(f"{TOPICS_FILE.relative_to(REPO_ROOT)}: 주제 이름이 중복된다")
    used_topics = {}
    for entry in questions:
        topic = entry.get("topic", "")
        if topic not in study_topics:
            fail(entry, f'topic이 주제별 메뉴에 없는 값이다: "{topic}"')
        else:
            used_topics[topic] = used_topics.get(topic, 0) + 1
    for topic in study_topics:
        if topic not in used_topics:
            errors.append(f"{TOPICS_FILE.relative_to(REPO_ROOT)}: 주제 \"{topic}\"에 해당하는 문항이 없다")

    print(f"문항 {len(questions)}개 검사, 주제 {len(used_topics)}/{len(study_topics)}개 사용")
    for year in sorted(years, reverse=True):
        print(f"  {year}: {years[year]}문항")

    if errors:
        print(f"\n오류 {len(errors)}건:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1

    print("이상 없음")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ParseError as exc:
        print(f"파싱 실패: {exc}", file=sys.stderr)
        sys.exit(2)
