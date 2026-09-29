#!/usr/bin/env python3
"""지원 웹페이지(docs/)를 검사한다.

App Store Connect에 등록하는 고객지원·개인정보처리방침 주소가 이 폴더의 파일이라,
파일이 빠지거나 페이지 사이 링크가 깨지면 심사에서 문제가 된다.

사용법: python3 Scripts/check_docs.py
"""

from __future__ import annotations

import re
import sys
from html.parser import HTMLParser
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS = REPO_ROOT / "docs"
# App Store Connect에 등록하는 페이지
REQUIRED_PAGES = ("index.html", "support.html", "privacy.html")
CONTACT_EMAIL = "jsnoh2010@gmail.com"


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.refs: list[str] = []
        self.title = ""
        self._in_title = False
        self.has_viewport = False

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        for key in ("href", "src"):
            if a.get(key):
                self.refs.append(a[key])
        if tag == "title":
            self._in_title = True
        if tag == "meta" and a.get("name") == "viewport":
            self.has_viewport = True

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False

    def handle_data(self, data):
        if self._in_title:
            self.title += data


def main() -> int:
    errors: list[str] = []
    for name in REQUIRED_PAGES:
        if not (DOCS / name).exists():
            errors.append(f"docs/{name}이 없다 (App Store Connect에 등록하는 페이지)")

    for page in sorted(DOCS.glob("*.html")):
        text = page.read_text(encoding="utf-8")
        parser = PageParser()
        parser.feed(text)
        where = f"docs/{page.name}"
        if not parser.title.strip():
            errors.append(f"{where}: <title>이 비어 있다")
        if not parser.has_viewport:
            errors.append(f"{where}: viewport meta가 없어 휴대폰에서 작게 보인다")
        for ref in dict.fromkeys(parser.refs):
            if re.match(r"^(https?:|mailto:|#)", ref):
                continue
            target = (DOCS / ref.split("#")[0].split("?")[0]).resolve()
            if not target.exists():
                errors.append(f"{where}: 링크 대상 \"{ref}\"가 없다")
        if page.name in ("support.html", "privacy.html") and CONTACT_EMAIL not in text:
            errors.append(f"{where}: 문의 이메일({CONTACT_EMAIL})이 없다")

    if errors:
        print(f"오류 {len(errors)}건:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print(f"docs 페이지 {len(list(DOCS.glob('*.html')))}개 이상 없음")
    return 0


if __name__ == "__main__":
    sys.exit(main())
