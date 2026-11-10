#!/usr/bin/env python3
"""A small stdio client for the engine's headless MCP host, Sedulous.Tools.Mcp, for the template
authoring script: one host process, tool calls answered one at a time, each result parsed.

    host = Host()
    guid = host.call("asset_list", {})
    host.close()
"""
import json, os, subprocess

# The engine checkout: $SEDULOUS_ROOT, else the one these tools sit in (Data/Templates/Tools).
ENGINE = os.environ.get("SEDULOUS_ROOT",
                        os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../..")))
TOOLS_MCP = os.environ.get("SEDULOUS_TOOLS_MCP",
                           ENGINE + "/Code/build/Debug_Linux64/Sedulous.Tools.Mcp/Sedulous.Tools.Mcp")


class Host:
    """One Sedulous.Tools.Mcp, run from the checkout over its Data, initialized."""

    def __init__(self):
        if not os.path.isfile(TOOLS_MCP):
            raise SystemExit("no MCP host at %s: build Sedulous.Tools.Mcp (Debug) first" % TOOLS_MCP)
        self.proc = subprocess.Popen([TOOLS_MCP, "--data-root", os.path.join(ENGINE, "Data")], cwd=ENGINE,
                                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        self.next_id = 0
        self.rpc("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                "clientInfo": {"name": "make-templates", "version": "1"}})

    def rpc(self, method, params):
        self.next_id += 1
        ident = self.next_id
        self.proc.stdin.write(json.dumps({"jsonrpc": "2.0", "id": ident, "method": method, "params": params}) + "\n")
        self.proc.stdin.flush()
        while True:
            line = self.proc.stdout.readline()
            if not line:
                raise SystemExit("Sedulous.Tools.Mcp closed during %s" % method)
            msg = json.loads(line)
            if msg.get("id") == ident:
                return msg

    def call(self, tool, args):
        """One tool call; its result parsed as JSON (or {"text": ...}). Exits on an error."""
        r = self.rpc("tools/call", {"name": tool, "arguments": args})
        if "error" in r:
            raise SystemExit("%s failed: %s" % (tool, json.dumps(r["error"])[:2000]))
        result = r["result"]
        text = "".join(part.get("text", "") for part in result.get("content", []))
        if result.get("isError"):
            raise SystemExit("%s failed: %s" % (tool, text[:2000]))
        try:
            return json.loads(text)
        except ValueError:
            return {"text": text}

    def close(self):
        self.proc.stdin.close()
        self.proc.wait(timeout=120)
