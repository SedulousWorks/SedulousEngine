#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026-Present Robert Campbell

"""Generates the AudioPlayground sample's tiny WAV assets procedurally (16-bit PCM).

Run from this directory: python3 generate_audio.py
The .wav files are committed as generated data so the sample needs no downloads
and licensing is a non-issue.
"""
import math
import random
import struct
import wave


def write_wav(name, samples, rate, channels=1):
    with wave.open(name, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
                               for s in samples))
    print(f"{name}: {len(samples) // channels} frames @ {rate} Hz")


def envelope(i, n, attack=0.02, release=0.25):
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return min(a, r)


def ambient(rate=11025, seconds=3.0):
    """A gentle looping minor-chord pad with slow tremolo.

    Voiced in the mid range (A3 root) ON PURPOSE: the original 110/165/220 Hz
    voicing was inaudible on typical laptop speakers - it played fine and nobody
    could hear it. Keep pads >= ~220 Hz so the sample is audible everywhere.
    """
    n = int(rate * seconds)
    out = []
    for i in range(n):
        t = i / rate
        tremolo = 0.8 + 0.2 * math.sin(2 * math.pi * t / seconds * 2)
        s = 0.0
        for k, freq in enumerate((220.0, 330.0, 440.0, 660.0)):
            # Integer number of cycles over the loop so it loops clean.
            cycles = round(freq * seconds)
            s += math.sin(2 * math.pi * cycles * t / seconds) / (k + 1)
        out.append(0.16 * tremolo * s)
    return out, rate


def beep(freq, rate=22050, seconds=0.22):
    n = int(rate * seconds)
    return [0.55 * envelope(i, n) * math.sin(2 * math.pi * freq * i / rate)
            for i in range(n)], rate


def click(rate=22050, seconds=0.08):
    random.seed(7)
    n = int(rate * seconds)
    return [0.5 * envelope(i, n, attack=0.001, release=0.9)
            * (random.random() * 2 - 1) for i in range(n)], rate


samples, rate = ambient()
write_wav("ambient_loop.wav", samples, rate)
samples, rate = beep(880.0)
write_wav("beep_high.wav", samples, rate)
samples, rate = beep(330.0, seconds=0.3)
write_wav("beep_low.wav", samples, rate)
samples, rate = click()
write_wav("click.wav", samples, rate)
