namespace Sedulous.UI;

/// When to show a scrollbar.
public enum ScrollBarPolicy
{
	/// Never show — scroll via wheel/drag only.
	Never,
	/// Show only when content exceeds viewport.
	Auto,
	/// Always show, even when content fits.
	Always
}
