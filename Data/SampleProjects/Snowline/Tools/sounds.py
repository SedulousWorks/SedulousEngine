#!/usr/bin/env python3
"""sounds.py [--kenney <dir>] [--music <dir>]: Snowline's sounds, imported through the editor's MCP.

Generated here (no third-party content):

- Audio/Wind: four seconds of wind, looping seamlessly (its last half second crossfaded into its
  first): noise through two low-pass filters (a low roar and a thinner hiss), swelling in slow
  gusts. Board.as plays it on the rider's Wind source, louder and higher as the rider goes faster.
- Audio/Rumble: four seconds of an avalanche's roar, looping the same way: noise through a very low
  filter, thudding unevenly. Avalanche.as plays it on its Rumble source, louder as it closes in.

Taken from Kenney's packs (CC0; `--kenney` is the folder holding the unzipped packs), each imported
under the name the game knows it by (KENNEY): the board's pop, landing, crash and a hit on a tree;
a gate passed and missed; the menus' click and back; the medal and no-medal stings.

The music (`--music` holds the downloads; CREDITS.md says where each is from): Audio/MusicTitle,
"Slippery Slope" by RaisinRiot (CC-BY 3.0), converted from its WAV to Ogg Vorbis; Audio/MusicRun,
"Black Diamond" by Joth (CC0), as published. Both stream rather than decode whole.
With neither option, the files already in generated/Audio are imported (each once, found by name
after), the generated ones made first if they are missing.
"""
import math, os, random, struct, sys, wave
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from snowgen import mcp, assets

RATE = 22050


def wind(path, seconds=4.0, fade=0.5):
    rnd = random.Random(31)
    total = int((seconds + fade) * RATE)
    low = hiss = 0.0
    raw = []
    for i in range(total):
        white = rnd.uniform(-1.0, 1.0)
        low += (white - low) * 0.02    # the roar
        hiss += (white - hiss) * 0.25  # the hiss
        t = i / RATE
        gust = 0.65 + 0.35 * math.sin(2 * math.pi * t / seconds) * math.sin(2 * math.pi * t * 0.73 / seconds + 1.0)
        raw.append((low * 3.2 + hiss * 0.35) * gust)
    n, f = int(seconds * RATE), int(fade * RATE)
    out = raw[:n]
    for i in range(f):  # the tail fades into the head, so the loop has no seam
        k = i / f
        out[i] = raw[n + i] * (1.0 - k) + raw[i] * k
    peak = max(abs(v) for v in out) or 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v / peak * 0.8 * 32767)) for v in out))


def rumble(path, seconds=4.0, fade=0.5):
    rnd = random.Random(53)
    total = int((seconds + fade) * RATE)
    deep = low = 0.0
    thud = 0.0
    raw = []
    for i in range(total):
        white = rnd.uniform(-1.0, 1.0)
        deep += (white - deep) * 0.004  # the ground's roar
        low += (white - low) * 0.03     # snow churning over it
        if rnd.random() < 6.0 / RATE:   # a few uneven thuds a second
            thud = rnd.uniform(0.6, 1.0)
        thud *= 0.9993
        raw.append(deep * 9.0 * (0.7 + 0.6 * thud) + low * 0.6)
    n, f = int(seconds * RATE), int(fade * RATE)
    out = raw[:n]
    for i in range(f):
        k = i / f
        out[i] = raw[n + i] * (1.0 - k) + raw[i] * k
    peak = max(abs(v) for v in out) or 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v / peak * 0.85 * 32767)) for v in out))


def chime(path, notes=((1318.5, 0.0), (1975.5, 0.07)), seconds=0.7):
    total = int(seconds * RATE)
    out = [0.0] * total
    for freq, start in notes:
        for i in range(int(start * RATE), total):
            t = i / RATE - start
            ring = math.exp(-t * 7.0) * min(1.0, t / 0.003)  # a quick strike, then the ring dies
            out[i] += ring * (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t))
    peak = max(abs(v) for v in out) or 1.0
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v / peak * 0.8 * 32767)) for v in out))


# name: (pack, file) under the Kenney folder.
KENNEY = {
    "Pop": ("impact-sounds", "Audio/footstep_snow_000.ogg"),
    "Land": ("impact-sounds", "Audio/footstep_snow_003.ogg"),
    "Crash": ("impact-sounds", "Audio/impactSoft_heavy_002.ogg"),
    "TreeHit": ("impact-sounds", "Audio/impactWood_heavy_001.ogg"),
    "GatePass": ("interface-sounds", "Audio/select_002.ogg"),
    "GateMiss": ("interface-sounds", "Audio/error_004.ogg"),
    "Click": ("interface-sounds", "Audio/click_002.ogg"),
    "Back": ("interface-sounds", "Audio/back_002.ogg"),
    "Medal": ("music-jingles", "Audio/Pizzicato jingles/jingles_PIZZI02.ogg"),
    "NoMedal": ("music-jingles", "Audio/Steel jingles/jingles_STEEL06.ogg"),
}


def imported(path):
    """Audio/<name>, imported once: found by name after."""
    name = os.path.splitext(os.path.basename(path))[0]
    found = [a["guid"] for a in assets() if a["name"] == name and a["type"] == "AudioClipAsset"]
    if found:
        return found[0]
    guid = mcp("asset_import", {"source": path, "group": "Audio", "importer": "Audio"})["guid"]
    if name.startswith("Music"):
        stream(guid)
    print(name, guid)
    return guid


def stream(guid):
    """A music track streams rather than decoding whole."""
    import xml.etree.ElementTree as ET
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    root.find("object[@name='payload']").find("object").find("bool[@name='stream']").text = "true"
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})


def third_party(out, kenney, music):
    import shutil, subprocess
    for name, (pack, rel) in KENNEY.items():
        path = os.path.join(out, name + ".ogg")
        shutil.copyfile(os.path.join(kenney, pack, rel), path)
        imported(path)
    title = os.path.join(out, "MusicTitle.ogg")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", os.path.join(music, "SlipperySlope.wav"), "-c:a", "libvorbis",
                    "-q:a", "5", title], check=True)
    imported(title)
    run = os.path.join(out, "BlackDiamond.mp3")
    shutil.copyfile(os.path.join(music, "BlackDiamond.mp3"), os.path.join(out, "MusicRun.mp3"))
    imported(os.path.join(out, "MusicRun.mp3"))


def main():
    out = os.path.join(HERE, "generated", "Audio")
    os.makedirs(out, exist_ok=True)
    args = sys.argv[1:]
    kenney = args[args.index("--kenney") + 1] if "--kenney" in args else None
    music = args[args.index("--music") + 1] if "--music" in args else None
    if kenney and music:
        third_party(out, kenney, music)
        return
    for name, make in (("Wind.wav", wind), ("Rumble.wav", rumble), ("GemChime.wav", chime)):
        path = os.path.join(out, name)
        if not os.path.exists(path):
            make(path)
    for f in sorted(os.listdir(out)):
        imported(os.path.join(out, f))


main()
