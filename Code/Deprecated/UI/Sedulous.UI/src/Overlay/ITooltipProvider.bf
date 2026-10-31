namespace Sedulous.UI;

/// Implemented by a view that builds its own tooltip content rather than showing plain text.
///
/// The tooltip manager looks for this FIRST and falls back to the view's TooltipText.
interface ITooltipProvider
{
	/// Builds the content view. OWNERSHIP transfers to the tooltip. Null suppresses the
	/// tooltip entirely, which is how a view says "not here, not now".
	View CreateTooltipContent();
}
