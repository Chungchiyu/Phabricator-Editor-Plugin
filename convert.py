import subprocess
import re
import sys
from pathlib import Path
from urllib.parse import quote

# Windows consoles often default to a legacy codepage (e.g. cp950) that can't
# encode emoji like "✏" in our own print() messages below; force UTF-8 so the
# build's exit code reflects whether the artifacts were written, not whether
# the terminal can display the status message.
for _stream in (sys.stdout, sys.stderr):
    if hasattr(_stream, 'reconfigure'):
        _stream.reconfigure(encoding='utf-8', errors='replace')


PLUGIN_FILE = Path('plugin.js')
BOOKMARKLET_FILE = Path('plugin-inline.js')
BAT_TEMPLATE = Path('install-phab-editor.template.bat')
BAT_FILE = Path('install-phab-editor.bat')
BAT_NAME_PREFIX = '✏Phab Editor'


def minify_with_terser(js_code):
    """Minify JavaScript code using terser.

    Raises an exception if terser is not installed or minification fails.
    """
    try:
        result = subprocess.run(
            ['npx', '-y', 'terser', '--compress', '--mangle'],
            input=js_code,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        # Fallback when Node.js/npx is not installed.
        return js_code.strip()

    if result.returncode != 0:
        # Fallback when terser execution fails.
        return js_code.strip()
    return result.stdout.strip()


def build_bookmarklet(js_code):
    normalized = js_code.lstrip()
    if normalized.lower().startswith('javascript:'):
        normalized = normalized[len('javascript:'):].lstrip()
    wrapped = '(function(){' + normalized + '})()'
    # URL-encode the payload to make it safe for batch-file embedding.
    return 'javascript:' + quote(wrapped, safe='')


def extract_version(js_code):
    match = re.search(
        r"PLUGIN_VERSION\s*=\s*['\"]([^'\"]+)['\"]",
        js_code,
    )
    if not match:
        raise RuntimeError('Could not find PLUGIN_VERSION in plugin.js')
    return match.group(1)


def update_bat_bookmarklet(template_path, output_path, bookmarklet, version):
    """Render the installer batch file from its template.

    Reads the tracked template (placeholder bookmarklet/name) and writes the
    real, version-specific installer to output_path, which is a generated
    build artifact and not committed to git.
    """
    content = template_path.read_text(encoding='utf-8')

    start_marker = 'rem :::URL_START:::'
    end_marker = 'rem :::URL_END:::'
    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)
    if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
        msg = 'Could not locate URL markers in install-bookmarklet.bat'
        raise RuntimeError(msg)

    line_start = content.find('\n', start_idx)
    if line_start == -1:
        msg = 'Invalid install-bookmarklet.bat format near URL_START'
        raise RuntimeError(msg)
    line_start += 1

    before = content[:line_start]
    after = content[end_idx:]
    updated = before + bookmarklet + '\n' + after

    bm_name_line = f'set "BM_NAME={BAT_NAME_PREFIX} {version}"'
    updated_lines = []
    replaced_bm_name = False
    for line in updated.splitlines():
        if line.startswith('set "BM_NAME='):
            updated_lines.append(bm_name_line)
            replaced_bm_name = True
        else:
            updated_lines.append(line)

    if not replaced_bm_name:
        msg = 'Could not find BM_NAME line in install-bookmarklet.bat'
        raise RuntimeError(msg)

    output_path.write_text('\n'.join(updated_lines) + '\n', encoding='utf-8')


def main():
    # Read the source file
    content = PLUGIN_FILE.read_text(encoding='utf-8')
    version = extract_version(content)

    # Minify with terser
    print('Minifying plugin.js with terser...')
    minified = minify_with_terser(content)

    # Wrap as bookmarklet
    bookmarklet = build_bookmarklet(minified)

    # Write the output
    BOOKMARKLET_FILE.write_text(bookmarklet, encoding='utf-8')

    # Render the batch installer from its template.
    update_bat_bookmarklet(BAT_TEMPLATE, BAT_FILE, bookmarklet, version)

    original_size = len(content)
    minified_size = len(bookmarklet)
    ratio = (1 - minified_size / original_size) * 100
    print(
        f'Done: {original_size} -> {minified_size} bytes '
        f'({ratio:.1f}% reduction)'
    )
    print(f'Updated {BAT_FILE} with BM_NAME={BAT_NAME_PREFIX} {version}')


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)
