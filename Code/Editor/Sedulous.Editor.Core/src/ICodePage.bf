namespace Sedulous.Editor.Core;

/// A page that shows code (a script's, a shader's, a text file's): where a log line, a problem or
/// an outside request points, it shows.
interface ICodePage
{
	/// Moves the cursor to `line` and `column` (1-based; 0 is the start) and brings it into view.
	void ShowLine(uint32 line, uint32 column);
}
