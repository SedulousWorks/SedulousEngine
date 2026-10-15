"""Masquerade's look: two shared profiles (Masquerade Environment, Masquerade Post) every map's scene
names in its settings, so the look is tuned in one place (Lamplight's arrangement, its look.py).

Night: a deep blue sky and a soft blue ambient, so the lanterns, the windows and the chandeliers
light the ball and the crowd still reads between them. TAA, SSR for the polished marble, GTAO, bloom
on the flames, and auto exposure for walking from the courtyard into the bright ballroom. No SSGI:
the crowd is the budget, and the web build plays it too. Colours are sRGB, as entered anywhere.
"""
import xml.etree.ElementTree as ET
from scenegen import mcp, settings, num, assets

POST = dict(exposureEV=0.0, tonemapOperator=1, bloomEnabled=True, bloomThreshold=1.0, bloomKnee=0.6,
            bloomIntensity=0.06, aoMode=1, aoStrength=1.0, aoRadius=0.8, aoIntensity=1.0, ssrEnabled=True,
            ssrIntensity=1.0, aaMode=2, taaBlendFactor=0.97, taaVarianceGamma=1.25, fxaaSubpixel=0.75,
            autoExposure=True, autoExposureKey=0.18, autoExposureSpeed=1.5, autoExposureMinEV=-3.0,
            autoExposureMaxEV=5.0, gradingIntensity=1.0, ssgiEnabled=False, ssgiIntensity=1.0)
ENVIRONMENT = dict(ambientColor={"r": 0.22, "g": 0.27, "b": 0.42, "a": 1.0}, ambientIntensity=0.06, skyMode=0,
                   skyIntensity=0.15, skyBackgroundIntensity=0.25, skyRotation=0.0,
                   skyHorizon={"r": 0.10, "g": 0.13, "b": 0.24, "a": 1.0},
                   skyZenith={"r": 0.02, "g": 0.03, "b": 0.08, "a": 1.0},
                   skyGround={"r": 0.04, "g": 0.04, "b": 0.06, "a": 1.0}, sunIntensity=1.0, sunAngularSize=0.5,
                   turbidity=2.0, iblDiffuseIntensity=0.2, iblSpecularIntensity=0.4,
                   shadowDistance=40.0, shadowCascadeSplit=0.75, shadowFadeDistance=8.0)

ENVIRONMENTS = {"Night": ("Masquerade Environment", ENVIRONMENT)}

_profiles = {}


def profile(creator, asset_type, name, values):
    """The shared profile asset `name`, made the first time and its fields rewritten each time
    (through its envelope, as the editor reads it), so a scene's settings only name it."""
    listed = assets()
    found = [a["guid"] for a in listed if a["name"] == name and a["type"] == asset_type]
    guid = found[0] if found else mcp("asset_create", {"creator": creator, "name": name})["guid"]
    root = ET.fromstring(mcp("asset_data_read", {"guid": guid})["xml"])
    payload = root.find("object[@name='payload']").find("object")  # the stored object
    for key, value in values.items():
        field = payload.find("*[@name='%s']" % key)
        if field is None:
            raise SystemExit("%s has no field %s" % (name, key))
        if isinstance(value, dict):
            for channel, v in value.items():
                field.find("*[@name='%s']" % channel).text = num(float(v))
        else:
            field.text = num(value)
    mcp("asset_data_write", {"guid": guid, "xml": ET.tostring(root, encoding="unicode")})
    return guid


def look(doc, environment="Night"):
    """Name the shared profiles in a scene's settings: the post profile every map shares, and the
    environment the map asks for (ENVIRONMENTS)."""
    name, values = ENVIRONMENTS[environment]
    if name not in _profiles:
        _profiles[name] = profile("Environment Profile", "EnvironmentProfileAsset", name, values)
    if "postprocess" not in _profiles:
        _profiles["postprocess"] = profile("Post Process Profile", "PostProcessProfileAsset", "Masquerade Post", POST)
    doc.settings.append(settings("environment", source=1, profile=_profiles[name]))
    doc.settings.append(settings("postprocess", source=1, profile=_profiles["postprocess"]))
