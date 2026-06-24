"""Build a GitHub Release body: this version's CHANGELOG.md entry plus a
fixed installation-instructions block. Used by .github/workflows/release.yml.
"""
import sys
from pathlib import Path

CHANGELOG_FILE = Path('CHANGELOG.md')

INSTALL_INSTRUCTIONS = """## 安裝方式

1. 下載這個 Release 附件 `install-phab-editor.bat`
2. 雙擊執行（會跳出一個小視窗）
3. 選擇要安裝的瀏覽器：Chrome / Edge / Firefox / All
4. 等待安裝完成，瀏覽器可能會自動關閉再重開
5. 開啟 Phabricator，點擊書籤列上的「✏Phab Editor {version}」即可開始使用

找不到附件或想拿最新版？README 裡也有一個「永遠是最新版」的下載連結：
https://github.com/Chungchiyu/Phabricator-Editor-Plugin/releases/latest/download/install-phab-editor.bat
"""


def extract_changelog(version):
    text = CHANGELOG_FILE.read_text(encoding='utf-8')
    heading = f'## {version}'
    start = text.find(heading)
    if start == -1:
        return None
    start = text.find('\n', start) + 1
    end = text.find('\n## ', start)
    if end == -1:
        end = len(text)
    return text[start:end].strip()


def main():
    if len(sys.argv) != 2:
        print('Usage: python release_notes.py <version>', file=sys.stderr)
        sys.exit(1)

    version = sys.argv[1]
    changelog = extract_changelog(version)
    if changelog is None:
        changelog = f'_(CHANGELOG.md 裡找不到 {version} 的更新說明，請記得補上)_'

    install = INSTALL_INSTRUCTIONS.format(version=version)
    notes = f'## 更新內容\n\n{changelog}\n\n{install}'
    # Write raw UTF-8 bytes so this isn't at the mercy of the console's
    # locale codepage (e.g. cp950 on Windows can't encode "⇄").
    sys.stdout.buffer.write(notes.encode('utf-8'))


if __name__ == '__main__':
    main()
