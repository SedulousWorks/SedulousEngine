#!/usr/bin/env python3
"""drive.py [laps]: a closed-loop playtest of Block1 over pie_run. The bike laps the ring road
clockwise, steering with the left stick toward the next corner, and throws at each subscriber's
zone once when it is near and ahead. Short runs; the bike coasts between them."""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pkgen import mcp

ZONES = [(0, 17.6), (17.6, 0), (30.4, -20), (30.4, -10), (-30.4, 0), (10, 30.4)]
CORNERS = [(-24, -24), (24, -24), (24, 24), (-24, 24)]
STEP = 0.25


def read(run):
    last = run["samples"][-1]["values"]
    return last


def state():
    r = mcp("pie_run", {"duration": 0.02, "probes": [
        {"entity": "Bike", "fields": ["worldPosition", "rotation"]}, {"script": "m_delivered"}]})
    return read(r)


def heading(q):
    x, y, z, w = q
    fx = 2 * (x * z + w * y)
    fz = 1 - 2 * (x * x + y * y)
    return math.atan2(fx, fz)


def wrap(a):
    while a > math.pi:
        a -= 2 * math.pi
    while a < -math.pi:
        a += 2 * math.pi
    return a


def main():
    steps = int(sys.argv[1]) if len(sys.argv) > 1 else 400
    s = state()
    # Start toward the corner the bike is heading for.
    pos = s["Bike.worldPosition"]
    target = 0
    tried = set()
    for i in range(steps):
        pos = s["Bike.worldPosition"]
        h = heading(s["Bike.rotation"])
        tx, tz = CORNERS[target]
        dx, dz = tx - pos[0], tz - pos[2]
        dist = math.hypot(dx, dz)
        if dist < 5.0:
            target = (target + 1) % 4
            tx, tz = CORNERS[target]
            dx, dz = tx - pos[0], tz - pos[2]
            dist = math.hypot(dx, dz)
        err = wrap(math.atan2(dx, dz) - h)
        steer = max(-1.0, min(1.0, -err * 2.5))
        throttle = 0.55 if (dist < 9 or abs(err) > 0.5) else 1.0
        inputs = [{"at": 0.0, "gamepad": 0, "axis": "LeftX", "value": steer},
                  {"at": 0.0, "gamepad": 0, "axis": "LeftY", "value": -throttle}]
        fx, fz = math.sin(h), math.cos(h)
        for zi, (zx, zz) in enumerate(ZONES):
            if zi in tried:
                continue
            ox, oz = zx - pos[0], zz - pos[2]
            d = math.hypot(ox, oz)
            if 4 < d < 13.5 and (ox * fx + oz * fz) / d > 0.35:
                inputs += [{"at": 0.0, "key": "Space"}, {"at": 0.08, "key": "Space", "down": False}]
                tried.add(zi)
                print("throw at zone", zi, "from", [round(v, 1) for v in pos], "dist", round(d, 1))
                break
        r = mcp("pie_run", {"duration": STEP, "input": inputs, "probes": [
            {"entity": "Bike", "fields": ["worldPosition", "rotation"]}, {"script": "m_delivered"}], "every": 1.0})
        s = read(r)
        if i % 10 == 0:
            print(i, [round(v, 1) for v in s["Bike.worldPosition"]], "heading", round(math.degrees(heading(s["Bike.rotation"]))),
                  "target", CORNERS[target], "delivered", s["script.m_delivered"])
        if s["script.m_delivered"] >= 4:
            print("delivered", s["script.m_delivered"], "at step", i)
            shot = mcp("pie_screenshot", {})
            print(shot.get("path"))
            return
    print("ran out of steps; delivered", s["script.m_delivered"])


main()
