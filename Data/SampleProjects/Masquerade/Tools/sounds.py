#!/usr/bin/env python3
"""sounds.py: Masquerade's music and sounds, generated here (no third-party content) and imported
through the editor's MCP into Audio/.

The orchestra's three pieces, one for each cue (Orchestra.as plays the cue's piece on every peer,
so the music is the cue a player must follow), each a seamless loop (its tail folded into its head):
- Audio/Waltz: the stroll, a waltz in D, oom-pah-pah under a flute.
- Audio/Air: gathering to talk, a slow air in G, held strings under a harp and a soft flute.
- Audio/Dance: the dance, a quick contredanse in A, plucked bass and a running flute.

The ball and the round:
- Audio/Murmur: the crowd talking, six seconds looping, under everything.
- Audio/Tag: a mark tagged, a fan's snap and two rising notes.
- Audio/Miss: the wrong guest, a falling buzz.
- Audio/Flare: a mask flares, a rising shimmer.
- Audio/Chime: a note for the player, one soft bell.
- Audio/Fanfare: the round's end, a bright arpeggio.
- Audio/Click: a button.
"""
import math, os, random, struct, sys, wave
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

RATE = 22050
OUT = os.path.join(HERE, "generated", "Sounds")
TWO_PI = 2.0 * math.pi


def write(path, samples, level=0.8):
    peak = max(1e-6, max(abs(v) for v in samples))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v / peak * level * 32767)) for v in samples))


def lowpass(samples, k):
    out, y = [], 0.0
    for v in samples:
        y += k * (v - y)
        out.append(y)
    return out


def freq(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# ---- instruments: each adds a note into `out` at sample `at` ----

def pluck(out, at, midi, seconds, amp, bright=0.5, rnd=random.Random(1)):
    """A plucked string (Karplus-Strong): the harp, the pizzicato bass."""
    period = max(2, int(RATE / freq(midi)))
    buf = [rnd.uniform(-1, 1) for _ in range(period)]
    n = min(int(seconds * RATE), len(out) - at)
    damp = 0.996 if midi < 50 else 0.994
    for t in range(n):
        i = t % period
        v = buf[i]
        out[at + t] += amp * v
        buf[i] = damp * (bright * v + (1.0 - bright) * 0.5 * (v + buf[(i + 1) % period]))


def flute(out, at, midi, seconds, amp):
    """A breathy flute: a sine with a little of its octave, vibrato, a soft attack and release."""
    f = freq(midi)
    n = min(int(seconds * RATE), len(out) - at)
    attack, release = int(0.04 * RATE), int(0.08 * RATE)
    phase = 0.0
    for t in range(n):
        vib = 1.0 + 0.004 * math.sin(TWO_PI * 5.2 * t / RATE) * min(1.0, t / (0.25 * RATE))
        phase += TWO_PI * f * vib / RATE
        env = min(1.0, t / attack) * min(1.0, (n - t) / release)
        out[at + t] += amp * env * (math.sin(phase) + 0.25 * math.sin(2 * phase) + 0.06 * math.sin(3 * phase))


def strings(out, at, midi, seconds, amp):
    """Held strings: a few soft harmonics, slightly detuned pairs, a slow swell."""
    f = freq(midi)
    n = min(int(seconds * RATE), len(out) - at)
    attack, release = int(0.35 * RATE), int(0.4 * RATE)
    for t in range(n):
        env = min(1.0, t / attack) * min(1.0, (n - t) / release)
        x = TWO_PI * t / RATE
        v = 0.0
        for h, a in ((1, 1.0), (2, 0.45), (3, 0.22), (4, 0.1)):
            v += a * (math.sin(x * f * h) + math.sin(x * f * h * 1.003))
        out[at + t] += amp * env * 0.5 * v


def fold(out, length):
    """A seamless loop of `length` samples: what rings on past the end folds into the start."""
    loop = out[:length]
    for t in range(length, len(out)):
        loop[t - length] += out[t]
    return loop


# ---- the pieces: chords by bar (MIDI roots and their tones), a melody chosen from chord tones ----

def chord(root, minor=False, seventh=False):
    tones = [root, root + (3 if minor else 4), root + 7]
    if seventh:
        tones.append(root + 10)
    return tones


def melody_line(rnd, bars, beats_per_bar, rhythm_choices, low, high):
    """For each bar, notes (beat offset, beats long, midi) on the bar's chord tones, stepping near
    the last note so the line sings rather than leaps."""
    line, last = [], (low + high) // 2
    for b, tones in enumerate(bars):
        rhythm = rnd.choice(rhythm_choices)
        beat = 0.0
        for length in rhythm:
            cands = [t + 12 * o for t in tones for o in range(-1, 4) if low <= t + 12 * o <= high]
            cands.sort(key=lambda m: abs(m - last) + rnd.uniform(0, 2.5))
            note = cands[0] if (b == len(bars) - 1 and beat == 0) else cands[min(len(cands) - 1, rnd.randrange(2))]
            line.append((b * beats_per_bar + beat, length, note))
            last, beat = note, beat + length
    return line


def waltz():
    """The stroll: a waltz in D at 150 beats a minute, sixteen bars."""
    rnd = random.Random(7)
    beat = 60.0 / 150.0
    D, G, A, B, E = 50, 55, 57, 59, 52
    bars = [chord(D), chord(D), chord(A, seventh=True), chord(A, seventh=True),
            chord(D), chord(D), chord(G), chord(G),
            chord(D), chord(B, minor=True), chord(E, minor=True), chord(A, seventh=True),
            chord(D), chord(G), chord(A, seventh=True), chord(D)]
    length = int(len(bars) * 3 * beat * RATE)
    out = [0.0] * (length + int(2.5 * RATE))
    for b, tones in enumerate(bars):
        at = int(b * 3 * beat * RATE)
        pluck(out, at, tones[0] - 12, 1.2, 0.9, 0.6)                    # oom
        for k in (1, 2):                                                  # pah, pah
            for m in tones[1:3]:
                pluck(out, at + int(k * beat * RATE), m + 12, 0.35, 0.28, 0.4)
    for start, beats, note in melody_line(rnd, bars, 3, [(3,), (2, 1), (1, 1, 1), (1.5, 0.5, 1)], 66, 86):
        flute(out, int(start * beat * RATE), note, beats * beat * 0.95, 0.32)
    return fold(out, length)


def air():
    """Gathering: a slow air in G at 66 beats a minute, eight bars of four."""
    rnd = random.Random(11)
    beat = 60.0 / 66.0
    G, E, C, D, A = 55, 52, 48, 50, 57
    bars = [chord(G), chord(E, minor=True), chord(C), chord(D),
            chord(G), chord(A, minor=True), chord(D, seventh=True), chord(G)]
    length = int(len(bars) * 4 * beat * RATE)
    out = [0.0] * (length + int(3.0 * RATE))
    for b, tones in enumerate(bars):
        at = int(b * 4 * beat * RATE)
        for m in tones[:3]:
            strings(out, at, m, 4 * beat + 0.3, 0.07)
        strings(out, at, tones[0] - 12, 4 * beat + 0.3, 0.06)
        for k in range(8):                                                # the harp's arpeggio
            m = tones[k % len(tones)] + 12 + (12 if k >= 4 else 0)
            pluck(out, at + int(k * 0.5 * beat * RATE), m, 1.6, 0.18, 0.3)
    for start, beats, note in melody_line(rnd, bars, 4, [(4,), (2, 2), (3, 1)], 67, 84):
        flute(out, int(start * beat * RATE), note, beats * beat * 0.97, 0.22)
    return fold(out, length)


def dance():
    """The dance: a contredanse in A at 132 beats a minute, sixteen bars of two."""
    rnd = random.Random(23)
    beat = 60.0 / 132.0
    A, D, E, Fs = 57, 50, 52, 54
    bars = [chord(A), chord(A), chord(E), chord(E), chord(A), chord(D), chord(E, seventh=True), chord(A),
            chord(Fs, minor=True), chord(D), chord(E), chord(E), chord(A), chord(D), chord(E, seventh=True), chord(A)]
    length = int(len(bars) * 2 * beat * RATE)
    out = [0.0] * (length + int(2.0 * RATE))
    for b, tones in enumerate(bars):
        at = int(b * 2 * beat * RATE)
        pluck(out, at, tones[0] - 12, 0.5, 0.9, 0.6)                     # root
        pluck(out, at + int(beat * RATE), tones[2] - 12, 0.5, 0.7, 0.6)  # fifth
        for k in (0.5, 1.5):                                              # chords on the offbeats
            for m in tones[:3]:
                pluck(out, at + int(k * beat * RATE), m + 12, 0.25, 0.2, 0.4)
    for start, beats, note in melody_line(rnd, bars, 2, [(0.5, 0.5, 0.5, 0.5), (1, 0.5, 0.5), (0.5, 0.5, 1)], 69, 88):
        flute(out, int(start * beat * RATE), note, beats * beat * 0.7, 0.3)
    return fold(out, length)


# ---- the sounds ----

def murmur(seconds=6.0, fade=0.6):
    """A ballroom's talk: voices of band-limited noise in syllables, overlapping, looping."""
    rnd = random.Random(5)
    total = int((seconds + fade) * RATE)
    out = [0.0] * total
    for v in range(10):
        noise = [rnd.uniform(-1, 1) for _ in range(total)]
        k1, k2 = rnd.uniform(0.08, 0.16), rnd.uniform(0.01, 0.03)
        band = [a - b for a, b in zip(lowpass(noise, k1), lowpass(noise, k2))]  # a voice's band
        t, amp = 0, rnd.uniform(0.5, 1.0)
        while t < total:  # syllables, and pauses between phrases
            n = int(rnd.uniform(0.08, 0.22) * RATE)
            for i in range(min(n, total - t)):
                out[t + i] += amp * band[t + i] * math.sin(math.pi * i / n)
            t += n + (int(rnd.uniform(0.3, 1.2) * RATE) if rnd.random() < 0.15 else int(0.02 * RATE))
    n, f = int(seconds * RATE), int(fade * RATE)
    loop = out[:n]
    for t in range(f):
        k = t / f
        loop[t] = out[t] * k + out[n + t] * (1 - k)
    return lowpass(loop, 0.5)


def ping(out, at, f, decay, amp):
    for t in range(len(out) - at):
        out[at + t] += amp * math.sin(TWO_PI * f * t / RATE) * math.exp(-t / (decay * RATE))


def tag():
    rnd = random.Random(3)
    out = [0.0] * int(0.7 * RATE)
    for t in range(int(0.03 * RATE)):  # the fan's snap
        out[t] += rnd.uniform(-1, 1) * math.exp(-t / (0.006 * RATE))
    for at, m in ((0.03, 81), (0.12, 88)):  # A5 then E6
        ping(out, int(at * RATE), freq(m), 0.25, 0.6)
        ping(out, int(at * RATE), freq(m) * 2, 0.12, 0.2)
    return out


def miss():
    n = int(0.5 * RATE)
    out, phase = [0.0] * n, 0.0
    for t in range(n):
        f = 220.0 * (1.0 - 0.35 * t / n)
        phase += TWO_PI * f / RATE
        env = math.exp(-t / (0.18 * RATE))
        out[t] = env * (math.sin(phase) + 0.5 * math.sin(3 * phase) + 0.3 * math.sin(5 * phase))
    return out


def flare():
    n = int(1.2 * RATE)
    out = [0.0] * n
    for p, a in ((1.0, 1.0), (1.5, 0.6), (2.0, 0.4), (3.0, 0.25)):
        phase = 0.0
        for t in range(n):
            f = 600.0 * p * (1.0 + 1.2 * t / n)
            phase += TWO_PI * f / RATE
            env = math.sin(math.pi * t / n) * (0.7 + 0.3 * math.sin(TWO_PI * 14 * t / RATE))
            out[t] += a * env * math.sin(phase)
    return out


def chime():
    out = [0.0] * int(1.2 * RATE)
    for ratio, a, decay in ((1.0, 1.0, 0.6), (2.0, 0.4, 0.4), (2.76, 0.2, 0.25)):
        ping(out, 0, freq(84) * ratio, decay, a)
    return out


def fanfare():
    out = [0.0] * int(2.6 * RATE)
    for k, m in enumerate((62, 66, 69, 74, 78)):  # D major, rising
        at = int(k * 0.14 * RATE)
        f = freq(m)
        hold = int((2.4 - k * 0.14) * RATE)
        for t in range(min(hold, len(out) - at)):
            env = min(1.0, t / (0.02 * RATE)) * math.exp(-t / (0.9 * RATE))
            x = TWO_PI * f * t / RATE
            out[at + t] += 0.4 * env * (math.sin(x) + 0.5 * math.sin(2 * x) + 0.33 * math.sin(3 * x) + 0.2 * math.sin(4 * x))
    return out


def click():
    out = [0.0] * int(0.06 * RATE)
    ping(out, 0, 1800.0, 0.01, 1.0)
    ping(out, 0, 3600.0, 0.005, 0.4)
    return out


SOUNDS = [("Waltz", waltz, 0.7), ("Air", air, 0.7), ("Dance", dance, 0.7), ("Murmur", murmur, 0.6),
          ("Tag", tag, 0.8), ("Miss", miss, 0.7), ("Flare", flare, 0.6), ("Chime", chime, 0.6),
          ("Fanfare", fanfare, 0.7), ("Click", click, 0.6)]


def main():
    os.makedirs(OUT, exist_ok=True)
    only = set(sys.argv[1:])
    for name, make, level in SOUNDS:
        if only and name not in only:
            continue
        path = os.path.join(OUT, name + ".wav")
        write(path, make(), level)
        print(name, mcp("asset_import", {"source": path, "group": "Audio", "importer": "Audio"})["guid"])
    print(mcp("asset_cook", {}))


if __name__ == "__main__":
    main()
