#!/usr/bin/env python3
"""lessons.py: the gallery's lessons, in teaching order, the one table the other Tools scripts read.

Each lesson is a shader in shaders/ (its file name: NN_Name.hlsl), the material the hall shows it
with (its parameters by property name, the textures it binds by slot, and its blend and cull modes
when not opaque and back-culled), the mesh it stands on its plinth as, and the one line the
gallery's list says about it. Adding a lesson is a row here and its .hlsl; shaders.py, hall.py,
ui.py and the game script follow from the table.

A value the lesson leaves out keeps the shader's default, except where the material had a value of
the same name and type before (material_set_shader carries it: a new material's PBR BaseColor is
white), so a lesson whose shader shares one of PBR's names sets it.

Optional placement, for the exhibits that are not a ball on the plinth: `y` (the exhibit's height,
else EXHIBIT_Y in hall.py), `scale` (else 1.1), `offset` (x from the plinth's centre), `plinth`
(its size), and `pole` (a flagpole's height: the exhibit hangs from its top).
"""

# Generated textures (textures.py writes them into generated/; shaders.py imports them).
TILES = "Tiles"
NOISE = "Noise"
ROCK_COLOUR = "Rock030_Color"
ROCK_NORMAL = "Rock030_NormalGL"

# Material modes (the material page's Blend Mode and Cull Mode, as their stored numbers).
MASKED, ALPHA_BLEND = 1, 2
CULL_NONE = 0

LESSONS = [
    dict(n=1, name="UnlitColour", title="Unlit Colour", kind="unlit surface", mesh="Sphere",
         summary="The smallest shader: a properties block and Surface().",
         params={"Paint": (0.95, 0.45, 0.2, 1.0)}),
    dict(n=2, name="Textured", title="Textured", kind="lit surface", mesh="Sphere",
         summary="A texture and its sampler, the uv, the vertex colour; lit by the scene.",
         params={"Tiling": 2.0, "Roughness": 0.6}, textures={"Albedo": TILES}),
    dict(n=3, name="Lava", title="Lava", kind="lit surface", mesh="Sphere",
         summary="Time() makes it move; emission makes it glow.",
         params={"Speed": 0.2, "Glow": 4.0, "Scale": 3.0}),
    dict(n=4, name="Hologram", title="Hologram", kind="unlit surface", mesh="Knot",
         summary="viewDir makes a fresnel rim, screenPos scanlines; alpha on a blended material.",
         blend=ALPHA_BLEND),
    dict(n=5, name="TriplanarRock", title="Triplanar Rock", kind="lit surface", mesh="Rock",
         summary="Mapped by world position, no uv; a normal map turned into tangent space.",
         params={"Scale": 0.8, "Sharpness": 4.0}, textures={"RockColour": ROCK_COLOUR, "RockNormal": ROCK_NORMAL}),
    dict(n=6, name="Dissolve", title="Dissolve", kind="lit surface", mesh="Knot",
         summary="alpha on a masked material cuts holes, in the shadow too; a burning edge.",
         blend=MASKED, textures={"Pattern": NOISE}),
    dict(n=7, name="Waves", title="Waves", kind="lit surface", mesh="Water",
         summary="Vertex() moves the vertices into waves; the shadow and the light follow.",
         y=1.08, scale=1.0, plinth=(2.2, 0.95, 2.2)),
    dict(n=8, name="Wind", title="Wind", kind="lit surface", mesh="Flag",
         summary="Vertex() by localPosition: the hoist stays on the pole, the fly end flaps.",
         cull=CULL_NONE, scale=1.0, offset=-0.8, pole=2.0),
    dict(n=9, name="BuiltInPbr", title="Built-in PBR", kind="lit surface", mesh="Sphere",
         summary="The engine's own material written as a surface: the reference to start from.",
         params={"NormalStrength": 0.35, "Tiling": 2.0}, textures={"NormalMap": ROCK_NORMAL}),
    dict(n=10, name="Toon", title="Toon", kind="low-level", mesh="Knot",
         summary="Both stages written out: the light in bands, a shadow colour, a rim.",
         params={"BaseColor": (1.0, 0.55, 0.25, 1.0), "ShadowColor": (0.35, 0.12, 0.25, 1.0)}),
    dict(n=11, name="CustomLighting", title="Custom Lighting", kind="low-level", mesh="Sphere",
         summary="Walking the lights itself (LightsAt, LightAt, ShadowOf): half-Lambert and Blinn-Phong.",
         params={"BaseColor": (0.35, 0.55, 0.9, 1.0)}),
]


def shader_file(lesson):
    return "%02d_%s.hlsl" % (lesson["n"], lesson["name"])
