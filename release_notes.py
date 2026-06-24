"""Build a GitHub Release body: this version's CHANGELOG.md entry plus a
fixed installation-instructions block. Used by .github/workflows/release.yml.
"""
import sys
from pathlib import Path

CHANGELOG_FILE = Path('CHANGELOG.md')

INSTALL_INSTRUCTIONS = """## Installation

1. Download this release's `install-phab-editor.bat` attachment.
2. Double-click to run it (a small window will pop up).
3. Choose which browser to install for: Chrome / Edge / Firefox / All.
4. Wait for installation to finish; your browser may close and reopen automatically.
5. Open Phabricator and click the "✏Phab Editor {version}" bookmark to start using it.

Can't find the attachment, or want the newest version? README also has an \
"always latest" download link:
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
        changelog = (
            f'_(No changelog entry found for {version} in CHANGELOG.md '
            f'-- please add one.)_'
        )

    install = INSTALL_INSTRUCTIONS.format(version=version)
    notes = f'## What\'s Changed\n\n{changelog}\n\n{install}'
    # Write raw UTF-8 bytes so this isn't at the mercy of the console's
    # locale codepage (e.g. cp950 on Windows can't encode "⇄").
    sys.stdout.buffer.write(notes.encode('utf-8'))


if __name__ == '__main__':
    main()
