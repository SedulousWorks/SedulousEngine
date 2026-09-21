#!/usr/bin/env python3
"""Symbolize an ASan/LeakSanitizer log written with symbolize=0.

In-process symbolization deadlocks the editor on a LIVE leak check
(__lsan_do_recoverable_leak_check spawns llvm-symbolizer from a process with
a GPU driver's threads in it, and the pipe to it breaks), so the editor runs
are logged raw and symbolized here, after the fact:

  Code/Tools/asan-symbolize.py asan-editor.log > asan-editor.sym.log

Frames look like "#3 0x709fe4  (/path/exe+0x709fe4) (BuildId: ...)"; each
module's offsets go through llvm-symbolizer in one batch; only modules under
the Sedulous tree are symbolized, the rest are left as module+offset.
"""
import re
import shutil
import subprocess
import sys
from collections import defaultdict

FRAME = re.compile(r'^(\s*#\d+ 0x[0-9a-f]+)\s+\((\S+?)\+(0x[0-9a-f]+)\)(.*)$')


def symbolizer():
    for name in ('llvm-symbolizer', 'llvm-symbolizer-21', 'llvm-symbolizer-20', 'llvm-symbolizer-19'):
        path = shutil.which(name)
        if path:
            return path
    sys.exit('no llvm-symbolizer on PATH')


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    lines = open(sys.argv[1], encoding='utf-8', errors='replace').read().splitlines()
    wanted = defaultdict(set)
    for line in lines:
        m = FRAME.match(line)
        if m:
            wanted[m.group(2)].add(m.group(3))

    tool = symbolizer()
    names = {}
    for module, offsets in wanted.items():
        # The driver and system libraries carry no debug info worth minutes of DWARF
        # parsing; our own binaries are what the chain is read from.
        if '/Sedulous/' not in module:
            continue
        offsets = sorted(offsets)
        out = subprocess.run(
            [tool, '--obj=' + module, '--demangle', '--inlining=false', '--pretty-print'] + offsets,
            capture_output=True, text=True).stdout
        results = [chunk for chunk in out.strip().split('\n') if chunk.strip()]
        # One line per address with --pretty-print, "func at file:line:col".
        for offset, text in zip(offsets, results):
            names[(module, offset)] = text.strip()

    for line in lines:
        m = FRAME.match(line)
        if not m:
            print(line)
            continue
        text = names.get((m.group(2), m.group(3)))
        if text and not text.startswith('??'):
            print(f'{m.group(1)} in {text}')
        else:
            print(line)


if __name__ == '__main__':
    main()
