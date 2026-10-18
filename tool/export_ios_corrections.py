"""Regenerate correction fixtures using an existing HijriCalendar-iOS checkout.

Usage (from this repository root):
    python3 tool/export_ios_corrections.py /path/to/HijriCalendar-iOS
Requires Swift and Foundation on macOS. Never runs in consuming applications.
"""
import pathlib
import subprocess
import sys
import tempfile

root = pathlib.Path(__file__).resolve().parent.parent
ios = pathlib.Path(sys.argv[1]).resolve()
sources = sorted((ios / 'Sources' / 'HijriCalendar').glob('*.swift'))
if not sources:
    raise SystemExit('No iOS calendar sources found in the supplied checkout')
with tempfile.TemporaryDirectory(prefix='hijri-reference-') as temporary:
    binary = pathlib.Path(temporary) / 'export'
    subprocess.run(['swiftc', '-module-cache-path', str(pathlib.Path(temporary) / 'modules'),
                    *map(str, sources), str(root / 'tool' / 'export_ios_corrections.swift'),
                    '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True, cwd=root)
