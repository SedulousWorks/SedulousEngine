#!/usr/bin/env python3
"""A tiny MCP client for the engine's two hosts.

  mcp.py http <tool> [json-args]           one call to the editor (port $MCP_PORT, 7415)
  mcp.py http --list                       tools/list, names and first line
  mcp.py stdio <calls.json>                run [[tool, args], ...] through one Sedulous.Tools.Mcp
Prints each result's text (JSON pretty printed when it parses); exit 1 on an error result.
"""
import json, os, subprocess, sys, urllib.request

# The engine checkout (for Sedulous.Tools.Mcp in stdio mode): $SEDULOUS_ROOT, else the one this project
# sits in (Data/SampleProjects/PaperKid/Tools).
ENGINE = os.environ.get("SEDULOUS_ROOT",
                        os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")))
TOOLS_MCP = ENGINE + "/Code/build/Debug_Linux64/Sedulous.Tools.Mcp/Sedulous.Tools.Mcp"
PORT = int(os.environ.get("MCP_PORT", "7415"))
TOKEN = open(os.path.expanduser(os.environ.get("MCP_TOKEN_DIR", "~/.local/share/Sedulous") + "/mcp-token")).read().strip()
TIMEOUT = float(os.environ.get("MCP_TIMEOUT", "1800"))


def show(result):
    failed = bool(result.get("isError"))
    for part in result.get("content", []):
        text = part.get("text", "")
        try:
            print(json.dumps(json.loads(text), indent=1))
        except Exception:
            print(text)
    if "structuredContent" in result and not result.get("content"):
        print(json.dumps(result["structuredContent"], indent=1))
    return failed


def http_rpc(method, params, ident=1):
    body = json.dumps({"jsonrpc": "2.0", "id": ident, "method": method, "params": params}).encode()
    req = urllib.request.Request("http://127.0.0.1:%d/mcp" % PORT, data=body,
                                 headers={"Content-Type": "application/json",
                                          "Accept": "application/json, text/event-stream",
                                          "Authorization": "Bearer " + TOKEN})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        raw = resp.read().decode()
    if raw.startswith("event:") or raw.startswith("data:"):
        raw = "\n".join(l[5:] for l in raw.splitlines() if l.startswith("data:"))
    return json.loads(raw)


def main():
    mode = sys.argv[1]
    if mode == "http":
        if sys.argv[2] == "--list":
            r = http_rpc("tools/list", {})
            for t in r["result"]["tools"]:
                print(t["name"], "-", t.get("description", "").split(". ")[0][:110])
            return 0
        tool = sys.argv[2]
        args = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
        r = http_rpc("tools/call", {"name": tool, "arguments": args})
        if "error" in r:
            print(json.dumps(r["error"], indent=1))
            return 1
        return 1 if show(r["result"]) else 0
    if mode == "stdio":
        calls = json.load(open(sys.argv[2]))
        p = subprocess.Popen([TOOLS_MCP], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        def rpc(i, method, params):
            p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": i, "method": method, "params": params}) + "\n")
            p.stdin.flush()
            while True:
                line = p.stdout.readline()
                if not line:
                    raise SystemExit("Sedulous.Tools.Mcp closed")
                msg = json.loads(line)
                if msg.get("id") == i:
                    return msg
        rpc(0, "initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                              "clientInfo": {"name": "mcp.py", "version": "1"}})
        failed = False
        for i, (tool, args) in enumerate(calls, 1):
            print("##", tool)
            r = rpc(i, "tools/call", {"name": tool, "arguments": args})
            if "error" in r:
                print(json.dumps(r["error"], indent=1))
                failed = True
                break
            if show(r["result"]):
                failed = True
                break
        p.stdin.close()
        p.wait(timeout=60)
        return 1 if failed else 0
    raise SystemExit(__doc__)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (urllib.error.URLError, ConnectionError, OSError) as e:
        print("mcp.py: no editor answering on port %d (%s)" % (PORT, getattr(e, "reason", e)))
        sys.exit(2)
