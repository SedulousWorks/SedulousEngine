using System;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// A registered tool: its identity, the schema its arguments are checked against, and the
/// handler that runs it.
///
/// The handler reports failure through a MESSAGE rather than a code, because that text is
/// what reaches the agent and is the only thing it can act on.
class Tool
{
	/// Fills outResult and answers, or fills outError and fails. A failure here is a tool
	/// failure, not a protocol error, and still travels as a successful response. A handler
	/// that must let its host make progress first answers NotFinished; see ToolOutcome.
	public typealias Handler = delegate ToolOutcome(JsonValue arguments, JsonValue outResult,
		String outError);

	public String Name = new .() ~ delete _;
	public String Description = new .() ~ delete _;
	/// Owned. Emitted verbatim in tools/list and used to validate a call.
	public JsonValue InputSchema ~ delete _;
	public Handler Run ~ delete _;
	/// State the handler closes over, OWNED here so it dies with the tool. A Beef closure has
	/// no destructor of its own, so anything the handler allocates has to hang off something
	/// that does.
	public Object Context ~ delete _;

	public this(StringView name, StringView description, JsonValue inputSchema, Handler run,
		Object context = null)
	{
		Name.Set(name);
		Description.Set(description);
		InputSchema = inputSchema;
		Run = run;
		Context = context;
	}
}
