namespace Sedulous.GUI;

/// Flags controlling which debug overlays are drawn after the normal render pass.
/// Zero overhead when all flags are false - AnyEnabled is checked before any work.
public struct UIDebugDrawSettings
{
	/// Red outline around every view's bounds.
	public bool ShowBounds;

	/// Green fill for ViewGroup padding regions.
	public bool ShowPadding;

	/// Orange fill for LayoutParams margin regions.
	public bool ShowMargin;

	/// Numbered overlay showing draw order within parent.
	public bool ShowZOrder;

	/// Yellow highlight on the view under the cursor.
	public bool ShowHitTarget;

	/// Blue outline on focused view and ancestors with focus-within.
	public bool ShowFocusPath;

	/// Numbered focus arrows showing tab order.
	public bool ShowTabOrder;

	/// True if any debug flag is enabled.
	public bool AnyEnabled =>
		ShowBounds || ShowPadding || ShowMargin ||
		ShowZOrder || ShowHitTarget || ShowFocusPath || ShowTabOrder;
}
