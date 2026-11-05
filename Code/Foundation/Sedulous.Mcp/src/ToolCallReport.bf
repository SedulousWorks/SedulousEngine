using System;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// Where a tools/call is when the tool observer hears of it.
enum ToolCallPhase : uint8
{
	/// The tool answered NotFinished the first time: it keeps running across pumps.
	Started,
	/// The tool answered.
	Finished,
	/// It ended unanswered: its caller went away.
	Abandoned,
}

/// One step of a tools/call, as the tool observer hears it. A call that answers at once is heard
/// once, Finished; one that answers NotFinished is heard Started, then Finished or Abandoned.
/// Schema refusals, unknown tools and the other methods run no tool and are not heard. What it
/// points at is BORROWED for the observer's call.
struct ToolCallReport
{
	/// The server's number for the call, the same in each of its reports.
	public uint64 Serial;
	public ToolCallPhase Phase;
	public StringView Tool;
	/// The validated arguments; never null (no arguments read as an empty object).
	public JsonValue Arguments;
	/// The tool's.
	public ToolAnnotations Annotations;
	/// Finished: the tool failed.
	public bool IsError;
	/// Finished: the answer's text (its JSON) or the error message.
	public StringView Result;
	/// From the call's first entry to this report.
	public TimeSpan Elapsed;
}
