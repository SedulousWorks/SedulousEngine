using System;

namespace Sedulous.GUI;

/// What a loader or parser says about its input: a line (1-based; 0 when it is not known) and a
/// message. The markup loader and the CSS parser fill a list of them when given one, so a cook
/// can warn of what they dropped or fail on what they could not read; without one they log, as
/// a running GUI does.
class GuiDiagnostic
{
	public enum Severity : uint8
	{
		/// Something was dropped; the rest stands.
		case Warning;
		/// The input could not be read.
		case Error;
	}

	public Severity Level = .Warning;
	/// 1-based; 0 when not known.
	public uint32 Line = 0;
	public String Message = new .() ~ delete _;
}
