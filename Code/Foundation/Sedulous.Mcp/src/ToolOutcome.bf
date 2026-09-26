namespace Sedulous.Mcp;

/// What a tool's handler hands back.
///
/// Answered and Failed are the two finished outcomes, and a handler's plain `true` or `false`
/// converts to them, so a tool that answers at once is written as it always was. NotFinished
/// asks the host to keep the caller waiting and to re-enter the handler with the SAME
/// arguments on its next pump, until a call answers: for a tool that must let its host make
/// progress in between, a cook running on a background thread or a simulation that has to
/// advance frames. Such a handler keeps its own progress state across the re-entries and gives
/// up on its own timeout, because a host that stopped pumping and a handler that never answers
/// look the same to the caller.
enum ToolOutcome
{
	/// The result was filled in.
	case Answered;
	/// The error was filled in: a TOOL failure, which still travels as a successful response.
	case Failed;
	/// Not yet: re-enter with the same arguments next pump.
	case NotFinished;

	public static implicit operator ToolOutcome(bool answered) => answered ? .Answered : .Failed;

	public bool IsFinished => this != .NotFinished;
}
