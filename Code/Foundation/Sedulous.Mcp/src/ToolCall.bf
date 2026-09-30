using System;

namespace Sedulous.Mcp;

/// One tools/call as a tool that answers NotFinished sees it across its re-entries: the same
/// object every time the call comes back, so the tool keeps what it started in State rather
/// than recognising its own call by its arguments (two identical calls in flight at once, from
/// two agents, have the same arguments).
///
/// The server owns it. It lives from the call's first entry to its answer, or until the
/// transport says the caller went away (McpServer.AbandonCall); State is deleted with it, so a
/// tool puts its cleanup in its state's destructor.
class ToolCall
{
	/// The transport's identity for the call, or nought when it gave none (the call is then
	/// known by its line).
	public uint64 Id;
	/// This call answered NotFinished before, and this is it coming back.
	public bool IsReentry = false;
	/// What the tool keeps between entries. OWNED: deleted when the call ends or is abandoned.
	public Object State ~ delete _;
}
