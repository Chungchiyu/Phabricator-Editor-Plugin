import subprocess
import sys


def minify_with_terser(js_code):
    """Minify JavaScript code using terser.

    Raises an exception if terser is not installed or minification fails.
    """
    result = subprocess.run(
        ['npx', '-y', 'terser', '--compress', '--mangle'],
        input=js_code,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"terser minification failed (exit code {result.returncode}):\n"
            f"{result.stderr}"
        )
    return result.stdout.strip()


def main():
    # Read the source file
    with open('plugin.js', 'r') as f:
        content = f.read()

    # Minify with terser
    print("Minifying plugin.js with terser...")
    minified = minify_with_terser(content)

    # Wrap as bookmarklet
    bookmarklet = 'javascript:(()=>{' + minified + '})()'

    # Write the output
    with open('plugin-inline.js', 'w') as f:
        f.write(bookmarklet)

    original_size = len(content)
    minified_size = len(bookmarklet)
    ratio = (1 - minified_size / original_size) * 100
    print(
        f"Done: {original_size} -> {minified_size} bytes "
        f"({ratio:.1f}% reduction)"
    )


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
