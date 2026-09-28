using System;
using Sedulous.Core.Logging;

namespace Sedulous.Editor.Core;

/// One captured log line: full fidelity text, the category the message prefixed itself
/// with, and a monotonic sequence a consumer polls from.
class EditorLogEntry
{
	public LogLevel Level = .Information;
	/// The "Prefix" of a "Prefix: message" line, the engine's convention for naming the
	/// subsystem that spoke; empty when the line had none.
	public String Category = new .() ~ delete _;
	public String Message = new .() ~ delete _;
	/// 1 based across the run, never reused.
	public uint64 Sequence = 0;

	public void CopyTo(EditorLogEntry other)
	{
		other.Level = Level;
		other.Category.Set(Category);
		other.Message.Set(Message);
		other.Sequence = Sequence;
	}
}
