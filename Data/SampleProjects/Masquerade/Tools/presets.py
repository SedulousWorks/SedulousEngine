#!/usr/bin/env python3
"""presets.py: Masquerade's export presets, written through the editor's MCP (Snowline's four):
the Linux desktop (the Steam Deck template in a window: built for glibc 2.35, it runs on most
current distributions as well as on the Deck); the Steam Deck (its container-built template, a
1280x800 frame, fullscreen); the Windows desktop (the release Win64 template, windowed); and the
Web (the page is index.html, so the export serves at its root; held to landscape on a phone).
Each ships the credits. A browser cannot host, so the web build's title offers no Host
(the game asks NetFacade.CanHost).
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from scenegen import mcp

mcp("export_preset_set", {"name": "Linux64 Desktop", "platform": "Linux64", "templateId": "sedulous-steamdeck-release-0.1.0",
                          "playerName": "Masquerade", "outputSubdir": "Linux64", "additionalFiles": ["CREDITS.md"],
                          "overridesWindow": True})
mcp("export_preset_set", {"name": "Steam Deck", "platform": "Linux64", "templateId": "sedulous-steamdeck-release-0.1.0",
                          "playerName": "Masquerade", "outputSubdir": "SteamDeck",
                          "additionalFiles": ["CREDITS.md"], "overridesRender": True, "renderWidth": 1280,
                          "renderHeight": 800, "overridesWindow": True, "windowMode": "Fullscreen", "windowResizable": False})
mcp("export_preset_set", {"name": "Web", "platform": "Web", "templateId": "sedulous-web-release-0.1.0",
                          "playerName": "index", "outputSubdir": "Web", "additionalFiles": ["CREDITS.md"],
                          "overridesOrientation": True, "orientation": "Landscape"})
mcp("export_preset_set", {"name": "Windows Desktop", "platform": "Win64", "templateId": "sedulous-win64-release-0.1.0",
                          "playerName": "Masquerade", "outputSubdir": "Windows64", "additionalFiles": ["CREDITS.md"],
                          "overridesWindow": True, "windowWidth": 1280, "windowHeight": 720, "windowMode": "Windowed",
                          "windowResizable": True})
print(mcp("export_presets", {}))
