#!/usr/bin/env python3
"""The sample games for a release, for the project manager's Samples tab.

  python3 Code/Tools/pack-samples.py <out-dir>

Packs the games Data/SampleProjects/Samples.json lists: for each, a zip of what git tracks in its
folder less Tools/ (the authoring scripts), its Project.xml at the zip's root (the manager
extracts it into the folder the user chooses), as sample-<folder>.zip; its picture as
sample-<folder>.png; and samples.json naming them, with each zip's size and SHA-256 and the bytes
it unpacks to. The version is the engine's own with its label, the release's (0.1.0-beta)
(Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf: String and Label): pack from the release
commit, not from master between releases, whose label is dev. The project manager reads
samples.json from the release of the engine picked on its Samples tab (tag v<version>).

Run by hand, in a checkout (only tracked files go in), and attach everything it writes to the
GitHub release v<version>: there is no workflow that does it. The same files pack to the same
bytes (fixed timestamps), so a rerun changes nothing it does not have to.
"""
import hashlib, json, os, re, shutil, subprocess, sys, zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
VERSION_FILE = os.path.join(ROOT, "Code", "Engine", "Sedulous.Engine.Project", "src", "EngineVersion.bf")


def engine_version():
    """The version with its label: the release's tag less its v."""
    text = open(VERSION_FILE, encoding="utf-8").read()
    found = re.search(r'public const String String = "([0-9]+\.[0-9]+\.[0-9]+)";', text)
    if not found:
        sys.exit(f"no version in {VERSION_FILE}")
    label = re.search(r'public const String Label = "([^"]*)";', text)
    if not label:
        sys.exit(f"no label in {VERSION_FILE}")
    return found.group(1) + ("-" + label.group(1) if label.group(1) else "")


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: Code/Tools/pack-samples.py <out-dir>")
    out = os.path.abspath(sys.argv[1])
    os.makedirs(out, exist_ok=True)
    version = engine_version()
    manifest = json.load(open(os.path.join(ROOT, "Data", "SampleProjects", "Samples.json"), encoding="utf-8"))

    listed = []
    for sample in manifest["samples"]:
        folder = sample["folder"]
        root = f"Data/SampleProjects/{folder}"
        files = subprocess.run(["git", "ls-files", "-z", "--", root], cwd=ROOT, check=True,
                               capture_output=True).stdout.decode("utf-8").split("\0")
        files = sorted(f for f in files if f and not f.startswith(f"{root}/Tools/"))
        if not any(f == f"{root}/Project.xml" for f in files):
            sys.exit(f"{folder}: no Project.xml tracked")
        archive = f"sample-{folder}.zip"
        path = os.path.join(out, archive)
        unpacked = 0
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
            for f in files:
                name = f[len(root) + 1:]
                info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0)) # fixed: the same files pack the same
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                data = open(os.path.join(ROOT, f), "rb").read()
                unpacked += len(data)
                z.writestr(info, data, compresslevel=9)
        digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
        picture = f"sample-{folder}.png"
        shutil.copyfile(os.path.join(ROOT, sample["picture"]), os.path.join(out, picture))
        listed.append({
            "folder": folder,
            "name": sample["name"],
            "description": sample["description"],
            "archive": archive,
            "size": os.path.getsize(path),
            "unpackedSize": unpacked,
            "sha256": digest,
            "picture": picture,
        })
        print(f"{archive}: {len(files)} files, {os.path.getsize(path) // 1024} KB packed, {unpacked // 1024} KB unpacked")

    json.dump({"version": version, "samples": listed}, open(os.path.join(out, "samples.json"), "w", encoding="utf-8"), indent=2)
    print(f"samples.json: {len(listed)} samples for {version}")


if __name__ == "__main__":
    main()
