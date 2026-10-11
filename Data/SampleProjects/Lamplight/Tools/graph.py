#!/usr/bin/env python3
"""graph.py: the characters' animation graphs (Models/<Name>/<Name>Graph), written through the
editor's MCP. The scripts drive them by parameters (scene.Animation SetFloat / SetBool), never by
naming clips:

- ThiefGraph (Thief.as): Speed (float, m/s) and Crouched (bool, the Sneak control held). Stand
  blends Idle, Walk and Run at the speeds their strides match (0, 1.6 and 4.5 m/s,
  blender/thief.py); Crouched blends Crouch and Sneak (0 and 1.0 m/s); the two cross-fade on
  Crouched.
- GuardGraph (Guard.as): Speed and Searching (bool, standing and looking round). Move blends Idle,
  Walk and Run (0, 1.2 and 4.0 m/s, blender/guard.py); Look plays while Searching.

Snowline's graph.py is the same writer for the rider's graph.
"""
import os, sys
import xml.etree.ElementTree as ET
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scenegen import mcp, assets

FLOAT, BOOL = 0, 2
EQUAL = 0
NIL = "00000000-0000-0000-0000-000000000000"

# Each graph: its model, parameters, states (name, loop, a clip or a blend: (param, [(threshold,
# clip)])), its first state, and transitions (src, dst, fade s, exit time or None, [(param, value)]).
GRAPHS = {
    "Thief": dict(
        params=[("Speed", FLOAT), ("Crouched", BOOL)],
        states=[("Stand", True, ("Speed", [(0.0, "Idle"), (1.6, "Walk"), (4.5, "Run")])),
                ("Crouched", True, ("Speed", [(0.0, "Crouch"), (1.0, "Sneak")]))],
        start="Stand",
        transitions=[("Stand", "Crouched", 0.25, None, [("Crouched", True)]),
                     ("Crouched", "Stand", 0.25, None, [("Crouched", False)])]),
    "Guard": dict(
        params=[("Speed", FLOAT), ("Searching", BOOL)],
        states=[("Move", True, ("Speed", [(0.0, "Idle"), (1.2, "Walk"), (4.0, "Run")])),
                ("Look", True, "Look")],
        start="Move",
        transitions=[("Move", "Look", 0.3, None, [("Searching", True)]),
                     ("Look", "Move", 0.3, None, [("Searching", False)])]),
}

listed = assets()


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


def write(model, g):
    group = "Models/" + model
    graph_name = model + "Graph"
    found = [a["guid"] for a in listed if a["type"] == "AnimationGraphAsset" and a["name"] == graph_name]
    guid = found[0] if found else mcp("asset_create", {"creator": "Animation Graph", "name": graph_name,
                                                       "group": group})["guid"]
    clip = lambda c: next(a["guid"] for a in listed if a["type"] == "AnimationClipAsset"
                          and a.get("group") == group and a["name"] == c)
    PARAMS = g["params"]
    P = {n: i for i, (n, _) in enumerate(PARAMS)}
    STATES = g["states"]
    S = {n: i for i, (n, _, _) in enumerate(STATES)}
    TRANSITIONS = [(S[src], S[dst], fade, exit_time, [(P[p], EQUAL, 1.0 if v else 0.0) for p, v in conds])
                   for src, dst, fade, exit_time, conds in g["transitions"]]
    # The graph's source as the engine stores it: every list flat (states, entries, transitions and
    # conditions each one array per field, a layer or state pointing at its run by start and count).
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
    arr(src, "layerName", ["Base"], "string")
    arr(src, "layerDefaultState", [str(S[g["start"]])], "i32")
    arr(src, "layerBlendModeValue", ["0"], "u8")
    arr(src, "layerWeight", ["1"], "f32")
    arr(src, "layerMaskStart", ["0"], "u32")
    arr(src, "layerMaskCount", ["0"], "u32")
    arr(src, "layerStateStart", ["0"], "u32")
    arr(src, "layerStateCount", [str(len(STATES))], "u32")
    arr(src, "layerTransitionStart", ["0"], "u32")
    arr(src, "layerTransitionCount", [str(len(TRANSITIONS))], "u32")
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
    arr(src, "transitionSource", [str(t[0]) for t in TRANSITIONS], "i32")
    arr(src, "transitionDest", [str(t[1]) for t in TRANSITIONS], "i32")
    arr(src, "transitionDuration", [repr(t[2]) for t in TRANSITIONS], "f32")
    arr(src, "transitionHasExitTime", ["true" if t[3] is not None else "false" for t in TRANSITIONS], "bool")
    arr(src, "transitionExitTime", [repr(t[3] if t[3] is not None else 1.0) for t in TRANSITIONS], "f32")
    arr(src, "transitionPriority", ["0" for _ in TRANSITIONS], "i32")
    cond_starts, cond_counts = [], []
    for t in TRANSITIONS:
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
    print(graph_name, guid)
    return guid




for model, g in GRAPHS.items():
    write(model, g)
