namespace Sedulous.UI.Toolkit;

/// What the gutter shows beside a line.
///
/// Three of these are SET directly and two are DERIVED: a breakpoint and a modified flag are
/// stored per line, while errors and warnings come from the diagnostic list and the execution
/// line from its own single slot. The document hands back the union, so the gutter reads one
/// mask and never asks three questions.
enum CodeMarkers : uint8
{
	None = 0,
	Breakpoint = 1 << 0,
	Error = 1 << 1,
	Warning = 1 << 2,
	ExecutionLine = 1 << 3,
	Modified = 1 << 4
}
