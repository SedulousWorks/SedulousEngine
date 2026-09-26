namespace Sedulous.Mcp;

/// What a tool does to the world, as MCP's tool annotations say it (tools/list emits them
/// under `annotations`): a client uses them to run reads freely and confirm writes, and the
/// editor host to decide what a call may do unattended. Every registration states its class;
/// there is no default, because an unannotated write reads as a read.
struct ToolAnnotations
{
	/// readOnlyHint: changes nothing.
	public bool IsReadOnly;
	/// destructiveHint: may overwrite or delete what exists.
	public bool IsDestructive;
	/// idempotentHint: calling again with the same arguments changes nothing more.
	public bool IsIdempotent;
	/// openWorldHint: reaches outside the project (never, here).
	public bool IsOpenWorld;

	public this(bool readOnly, bool destructive, bool idempotent, bool openWorld)
	{
		IsReadOnly = readOnly;
		IsDestructive = destructive;
		IsIdempotent = idempotent;
		IsOpenWorld = openWorld;
	}

	/// Reads and reports; changes nothing.
	public static Self ReadOnly => .(true, false, true, false);
	/// Adds something new (an asset, a log line, a project) without touching what exists.
	public static Self Creates => .(false, false, false, false);
	/// Replaces existing data (a scene's source); the same call again lands the same state.
	public static Self Overwrites => .(false, true, true, false);
	/// Regenerates derived output (a cook, a dist, the open project); nothing authored is lost.
	public static Self Rebuilds => .(false, false, true, false);
}
