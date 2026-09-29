#!/usr/bin/env python3
"""앱 아이콘과 실행 화면 이미지를 검사한다.

Xcode 빌드는 아이콘 크기가 틀리거나 1024 아이콘에 투명 채널이 있어도 경고만
내고 통과하지만, App Store Connect 업로드에서는 거절된다. 실행 화면이 가리키는
이미지가 에셋에 없으면 빈 화면이 뜬다. 이런 문제를 빌드 전에 잡는다.

사용법: python3 Scripts/check_assets.py   (Pillow 필요)
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from PIL import Image

REPO_ROOT = Path(__file__).resolve().parent.parent
ASSETS = REPO_ROOT / "PsyKNLE" / "Assets.xcassets"
APP_ICON = ASSETS / "AppIcon.appiconset"
LAUNCH_SCREEN = REPO_ROOT / "PsyKNLE" / "LaunchScreen.storyboard"
SWIFT_DIR = REPO_ROOT / "PsyKNLE"


def rel(path: Path) -> str:
    return str(path.relative_to(REPO_ROOT))


def check_app_icon(errors: list[str]) -> None:
    contents = json.loads((APP_ICON / "Contents.json").read_text(encoding="utf-8"))
    referenced = set()
    has_marketing = False
    for entry in contents.get("images", []):
        name = entry.get("filename")
        if not name:
            continue
        referenced.add(name)
        path = APP_ICON / name
        if not path.exists():
            errors.append(f"{rel(APP_ICON / 'Contents.json')}: {name} 파일이 없다")
            continue
        size = float(entry["size"].split("x")[0])
        scale = int(entry.get("scale", "1x").rstrip("x"))
        expected = round(size * scale)
        with Image.open(path) as im:
            if im.size != (expected, expected):
                errors.append(f"{rel(path)}: {im.size[0]}x{im.size[1]}px인데 {entry['size']}@{scale}x이면 {expected}px이어야 한다")
            if entry.get("idiom") == "ios-marketing":
                has_marketing = True
                if "A" in im.getbands() or "transparency" in im.info:
                    errors.append(f"{rel(path)}: App Store용 1024 아이콘에 투명 채널이 있으면 업로드가 거절된다")
    if not has_marketing:
        errors.append(f"{rel(APP_ICON / 'Contents.json')}: App Store용 1024 아이콘(ios-marketing)이 없다")
    for path in APP_ICON.glob("*.png"):
        if path.name not in referenced:
            errors.append(f"{rel(path)}: Contents.json에서 쓰지 않는 파일이다")


def asset_names() -> set[str]:
    return {p.stem for p in ASSETS.glob("*.imageset")}


def check_imagesets(errors: list[str]) -> None:
    for imageset in ASSETS.glob("*.imageset"):
        contents = json.loads((imageset / "Contents.json").read_text(encoding="utf-8"))
        for entry in contents.get("images", []):
            name = entry.get("filename")
            if name and not (imageset / name).exists():
                errors.append(f"{rel(imageset / 'Contents.json')}: {name} 파일이 없다")


def check_image_references(errors: list[str]) -> None:
    names = asset_names()
    storyboard = LAUNCH_SCREEN.read_text(encoding="utf-8")
    for name in sorted(set(re.findall(r'\bimage="([^"]+)"', storyboard))):
        if name not in names:
            errors.append(f"{rel(LAUNCH_SCREEN)}: 이미지 \"{name}\"가 Assets.xcassets에 없어 실행 화면에 나오지 않는다")
    for swift in sorted(SWIFT_DIR.glob("*.swift")):
        for name in re.findall(r'\bImage\("([^"]+)"\)', swift.read_text(encoding="utf-8")):
            if name not in names:
                errors.append(f"{rel(swift)}: Image(\"{name}\")에 해당하는 에셋이 없다")


def main() -> int:
    errors: list[str] = []
    check_app_icon(errors)
    check_imagesets(errors)
    check_image_references(errors)
    if errors:
        print(f"오류 {len(errors)}건:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        return 1
    print("앱 아이콘과 이미지 에셋 이상 없음")
    return 0


if __name__ == "__main__":
    sys.exit(main())
