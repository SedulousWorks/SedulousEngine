"""Snowline's look: two shared profiles (Snowline Environment, Snowline Post) every course's scene
names in its settings, so the look is tuned in one place (PaperKid's arrangement, its block.py).

Snow is bright: a cool, high-key look with a clear sky, blue shade and a fixed exposure that keeps
the snow off the clip. Colours are sRGB, as entered anywhere.
"""
import xml.etree.ElementTree as ET
from snowgen import mcp, assets, settings, num

POST = dict(exposureEV=0.6, tonemapOperator=1, bloomEnabled=True, bloomThreshold=1.2, bloomKnee=0.6,
            bloomIntensity=0.04, aoMode=2, aoStrength=1.0, aoRadius=1.0, aoIntensity=0.8, ssrEnabled=False,
            ssrIntensity=1.0, aaMode=1, taaBlendFactor=0.97, taaVarianceGamma=1.25, fxaaSubpixel=0.75,
            autoExposure=False, autoExposureKey=0.25, autoExposureSpeed=2.0, autoExposureMinEV=-4.0,
            autoExposureMaxEV=4.0, gradingIntensity=1.0, ssgiEnabled=False, ssgiIntensity=1.0)
ENVIRONMENT = dict(ambientColor={"r": 0.55, "g": 0.66, "b": 0.85, "a": 1.0}, ambientIntensity=0.12, skyMode=0,
                   skyIntensity=1.0, skyBackgroundIntensity=1.0, skyRotation=0.0,
                   skyHorizon={"r": 0.78, "g": 0.87, "b": 0.98, "a": 1.0},
                   skyZenith={"r": 0.22, "g": 0.45, "b": 0.86, "a": 1.0},
                   skyGround={"r": 0.85, "g": 0.88, "b": 0.92, "a": 1.0}, sunIntensity=1.0, sunAngularSize=0.5,
                   turbidity=2.5, iblDiffuseIntensity=0.4, iblSpecularIntensity=1.0,
                   shadowDistance=140.0, shadowCascadeSplit=0.75, shadowFadeDistance=20.0)

_profiles = {}


def profile(creator, asset_type, name, values):
    """The shared profile asset `name`, made the first time and its fields rewritten each time
    (through its envelope, as the editor reads it), so a scene's settings only name it."""
    found = [a["guid"] for a in assets() if a["name"] == name and a["type"] == asset_type]
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


def look(doc):
    """Name the shared profiles in a scene's settings."""
    if not _profiles:
        _profiles["environment"] = profile("Environment Profile", "EnvironmentProfileAsset",
                                           "Snowline Environment", ENVIRONMENT)
        _profiles["postprocess"] = profile("Post Process Profile", "PostProcessProfileAsset",
                                           "Snowline Post", POST)
    doc.settings.append(settings("environment", source=1, profile=_profiles["environment"]))
    doc.settings.append(settings("postprocess", source=1, profile=_profiles["postprocess"]))
