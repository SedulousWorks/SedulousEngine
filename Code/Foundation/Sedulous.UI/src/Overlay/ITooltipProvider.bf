namespace Sedulous.UI;

/// Implement on a View to provide custom tooltip content instead of
/// plain text. TooltipManager checks for this interface first; if not
/// implemented, falls back to View.TooltipText.
public interface ITooltipProvider
{
	/// Create the tooltip content view. Ownership transfers to TooltipView.
	/// Return null to suppress the tooltip.
	View CreateTooltipContent();
}
