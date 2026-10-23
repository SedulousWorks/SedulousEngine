#!/usr/bin/env python3
"""Rewrite stored vector image assets from the UI pipeline's type to VG.Pipeline's (2026-10-23).

The vector image moved out of the UI libraries: `Sedulous.UI.Pipeline.UIVectorImageAsset` became
`Sedulous.VG.Pipeline.VectorImageAsset` (and the cooked `Sedulous.UI.Resource.UIVectorImageResource`
became `Sedulous.VG.Resource.VectorImageResource`). An asset envelope names its type by its
qualified name and stores that name's id (TypeIdOf) in `dataVersions`, so a file written before the
move is unknown to a build after it. This script rewrites both in each `.xasset` that names the old
type. Anything else is left as it is.

Cooked/, Sources/, .cache/, Editor/ and Dist/ folders are skipped: the first recooks, the second is
raw imported data, the rest are generated.

Usage:
  Code/Tools/migrate-vector-image.py <path>... [--apply]

<path> is a file or a directory (walked for .xasset). Without --apply it only reports.
"""
import os
import sys

PRIME = 1099511628211
BASIS = 14695981039346656037
MASK = (1 << 64) - 1

OLD = "Sedulous.UI.Pipeline.UIVectorImageAsset"
NEW = "Sedulous.VG.Pipeline.VectorImageAsset"

#: A project's folders that are NOT its own stored data.
SKIPPED_DIRECTORIES = {"Cooked", "Sources", ".cache", "Editor", "Dist", ".git"}


def type_id(qualified_name):
    """TypeIdOf: FNV-1a 64 over the qualified name."""
    h = BASIS
    for byte in qualified_name.encode():
        h = ((h ^ byte) * PRIME) & MASK
    return h


def candidate_files(paths):
    for path in paths:
        if os.path.isfile(path):
            yield path
            continue
        for root, directories, names in os.walk(path):
            directories[:] = [d for d in directories if d not in SKIPPED_DIRECTORIES]
            for name in names:
                if name.endswith(".xasset"):
                    yield os.path.join(root, name)


def migrate(text):
    """The migrated text, or None when the file does not name the old type."""
    old_name = '<string name="typeName">%s</string>' % OLD
    if old_name not in text:
        return None
    text = text.replace(old_name, '<string name="typeName">%s</string>' % NEW)
    old_id = '<u64 name="type">%d</u64>' % type_id(OLD)
    return text.replace(old_id, '<u64 name="type">%d</u64>' % type_id(NEW))


def main(argv):
    apply = "--apply" in argv
    paths = [a for a in argv[1:] if a != "--apply"]
    if not paths:
        print(__doc__)
        return 2
    changed = 0
    for path in candidate_files(paths):
        with open(path, encoding="utf-8", newline="") as handle:
            text = handle.read()
        migrated = migrate(text)
        if migrated is None:
            continue
        changed += 1
        print(("migrated " if apply else "would migrate ") + path)
        if apply:
            with open(path, "w", encoding="utf-8", newline="") as handle:
                handle.write(migrated)
    print("%d file(s) %s" % (changed, "migrated" if apply else "to migrate (run with --apply)"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
