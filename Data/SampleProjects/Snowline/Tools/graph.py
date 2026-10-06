#!/usr/bin/env python3
"""graph.py: the rider's animation graph (Models/Rider/RiderGraph), written through the editor's MCP.

Board.as drives it by parameters (scene.Animation SetFloat / SetBool), never by naming clips:
- Lean (float, -1..1): the carve, heel edge to toe edge; Ride's state blends CarveHeel, Ride and
  CarveToe by it, and Tuck's TuckHeel, Tuck and TuckToe (a tucked rider leans into its turn too).
- Tuck, Airborne, Grab, Crashed (bools): the rider's situation, each its own state.

States: Ride (the lean blend), Tuck, Air, Grab, Land (once, then back to Ride), Crash (held while
Crashed). Every clip but Crash starts and ends in Ride's stance (blender/rider.py), so the cross
fades stay short.
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from snowgen import mcp, assets

FLOAT, BOOL = 0, 2
EQUAL = 0
PARAMS = [("Lean", FLOAT), ("Tuck", BOOL), ("Airborne", BOOL), ("Grab", BOOL), ("Crashed", BOOL)]
P = {name: i for i, (name, _) in enumerate(PARAMS)}

listed = assets()


def clip(name):
    return next(a["guid"] for a in listed if a["type"] == "AnimationClipAsset"
                and a.get("group") == "Models/Rider/RiderModel" and a["name"] == name)


def graph_guid():
    found = [a["guid"] for a in listed if a["type"] == "AnimationGraphAsset" and a["name"] == "RiderGraph"]
    return found[0] if found else mcp("asset_create", {"creator": "Animation Graph", "name": "RiderGraph",
                                                       "group": "Models/Rider"})["guid"]


NIL = "00000000-0000-0000-0000-000000000000"
# name, loop, clip or a blend: (param, [(threshold, clip)])
STATES = [
    ("Ride", True, ("Lean", [(-1.0, "CarveHeel"), (0.0, "Ride"), (1.0, "CarveToe")])),
    ("Tuck", True, ("Lean", [(-1.0, "TuckHeel"), (0.0, "Tuck"), (1.0, "TuckToe")])),
    ("Air", True, "Air"),
    ("Grab", True, "Grab"),
    ("Land", False, "Land"),
    ("Crash", False, "Crash"),
]
S = {name: i for i, (name, _, _) in enumerate(STATES)}


def when(param, value):
    return (P[param], EQUAL, 1.0 if value else 0.0)


# src, dst, fade (s), exit time (None = none), conditions
TRANSITIONS = [(S[s], S["Crash"], 0.12, None, [when("Crashed", True)]) for s in ("Ride", "Tuck", "Air", "Grab", "Land")]
TRANSITIONS += [
    (S["Crash"], S["Ride"], 0.25, None, [when("Crashed", False)]),
    (S["Ride"], S["Air"], 0.15, None, [when("Airborne", True)]),
    (S["Tuck"], S["Air"], 0.15, None, [when("Airborne", True)]),
    (S["Ride"], S["Tuck"], 0.2, None, [when("Tuck", True)]),
    (S["Tuck"], S["Ride"], 0.2, None, [when("Tuck", False)]),
    (S["Air"], S["Grab"], 0.15, None, [when("Grab", True)]),
    (S["Grab"], S["Air"], 0.2, None, [when("Grab", False)]),
    (S["Air"], S["Land"], 0.06, None, [when("Airborne", False)]),
    (S["Grab"], S["Land"], 0.06, None, [when("Airborne", False)]),
    (S["Land"], S["Ride"], 0.15, 0.9, []),
]


def el(parent, tag, name=None, text=None, **attrs):
    e = ET.SubElement(parent, tag, **({"name": name} if name else {}), **attrs)
    if text is not None:
        e.text = text
    return e


def arr(parent, name, items, tag):
    a = el(parent, "array", name, count=str(len(items)))
    for v in items:
        el(a, tag, text=v)
    return a


def write():
    """The graph's source as the engine stores it: every list flat (states, entries, transitions and
    conditions each one array per field, a layer or state pointing at its run by start and count)."""
    guid = graph_guid()
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']").find("object")
    for child in list(payload):
        if child.get("name") != "fileName":
            payload.remove(child)
    src = el(payload, "object", "source")
    arr(src, "paramName", [n for n, _ in PARAMS], "string")
    arr(src, "paramType", [str(t) for _, t in PARAMS], "u8")
    arr(src, "paramFloat", ["0" for _ in PARAMS], "f32")
    arr(src, "paramInt", ["0" for _ in PARAMS], "i32")
    arr(src, "paramBool", ["false" for _ in PARAMS], "bool")
    # One layer, holding every state and transition.
    transitions_written = [] if os.environ.get("RIDER_GRAPH_STILL") else TRANSITIONS
    arr(src, "layerName", ["Base"], "string")
    arr(src, "layerDefaultState", [str(S[os.environ.get("RIDER_GRAPH_START", "Ride")])], "i32")
    arr(src, "layerBlendModeValue", ["0"], "u8")
    arr(src, "layerWeight", ["1"], "f32")
    arr(src, "layerMaskStart", ["0"], "u32")
    arr(src, "layerMaskCount", ["0"], "u32")
    arr(src, "layerStateStart", ["0"], "u32")
    arr(src, "layerStateCount", [str(len(STATES))], "u32")
    arr(src, "layerTransitionStart", ["0"], "u32")
    arr(src, "layerTransitionCount", [str(len(transitions_written))], "u32")
    arr(src, "maskWeight", [], "f32")
    entries = []  # (threshold, clip) across every blend state, in state order
    starts, counts = [], []
    for name, loop, node in STATES:
        blend = isinstance(node, tuple)
        starts.append(str(len(entries)))
        counts.append(str(len(node[1]) if blend else 0))
        if blend:
            entries.extend(node[1])
    arr(src, "stateName", [n for n, _, _ in STATES], "string")
    arr(src, "stateSpeed", ["1" for _ in STATES], "f32")
    arr(src, "stateLoop", ["true" if loop else "false" for _, loop, _ in STATES], "bool")
    arr(src, "stateNodeKind", ["1" if isinstance(node, tuple) else "0" for _, _, node in STATES], "u8")
    arr(src, "stateNodeClip", [NIL if isinstance(node, tuple) else clip(node) for _, _, node in STATES], "string")
    arr(src, "stateNodeParamIndex", [str(P[node[0]]) if isinstance(node, tuple) else "-1" for _, _, node in STATES], "i32")
    arr(src, "stateNodeParamIndexX", ["-1" for _ in STATES], "i32")
    arr(src, "stateNodeParamIndexY", ["-1" for _ in STATES], "i32")
    arr(src, "stateEntryStart", starts, "u32")
    arr(src, "stateEntryCount", counts, "u32")
    arr(src, "entryThreshold", [repr(t) for t, _ in entries], "f32")
    el(src, "array", "entryPosition", count="0")
    arr(src, "entryClip", [clip(c) for _, c in entries], "string")
    conditions = []
    arr(src, "transitionSource", [str(t[0]) for t in transitions_written], "i32")
    arr(src, "transitionDest", [str(t[1]) for t in transitions_written], "i32")
    arr(src, "transitionDuration", [repr(t[2]) for t in transitions_written], "f32")
    arr(src, "transitionHasExitTime", ["true" if t[3] is not None else "false" for t in transitions_written], "bool")
    arr(src, "transitionExitTime", [repr(t[3] if t[3] is not None else 1.0) for t in transitions_written], "f32")
    arr(src, "transitionPriority", ["0" for _ in transitions_written], "i32")
    cond_starts, cond_counts = [], []
    for t in transitions_written:
        cond_starts.append(str(len(conditions)))
        cond_counts.append(str(len(t[4])))
        conditions.extend(t[4])
    arr(src, "transitionConditionStart", cond_starts, "u32")
    arr(src, "transitionConditionCount", cond_counts, "u32")
    arr(src, "conditionParamIndex", [str(c[0]) for c in conditions], "i32")
    arr(src, "conditionOp", [str(c[1]) for c in conditions], "u8")
    arr(src, "conditionThreshold", [repr(c[2]) for c in conditions], "f32")
    # Where the graph page draws each state (a column per situation).
    layouts = el(payload, "array", "layerLayouts", count="1")
    layout = el(layouts, "object")
    positions = el(layout, "array", "statePositions", count=str(len(STATES)))
    for i in range(len(STATES)):
        xy = el(positions, "object")
        el(xy, "f32", "x", repr(280.0 + 220.0 * (i % 3)))
        el(xy, "f32", "y", repr(120.0 + 160.0 * (i // 3)))
    anys = el(layout, "object", "anyStatePosition")
    el(anys, "f32", "x", "60")
    el(anys, "f32", "y", "40")
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    print("RiderGraph", guid)
    return guid


write()
