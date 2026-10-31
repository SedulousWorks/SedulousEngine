namespace Sedulous.UI;

/// Which debug overlays are drawn after the normal render pass.
///
/// Costs nothing when everything is off: AnyEnabled gates the whole pass rather than each
/// overlay checking itself.
struct UIDebugDrawSettings
{
	/// A red outline around every view's bounds.
	public bool ShowBounds = false;
	/// A green fill over padding regions.
	public bool ShowPadding = false;
	/// An orange fill over margin regions.
	public bool ShowMargin = false;
	/// A numbered overlay showing draw order within the parent.
	public bool ShowZOrder = false;
	/// A yellow highlight on the view under the cursor.
	public bool ShowHitTarget = false;
	/// A blue outline on the focused view and every ancestor holding focus within.
	public bool ShowFocusPath = false;
	/// Numbered arrows showing tab order.
	public bool ShowTabOrder = false;

	public this() {}

	public bool AnyEnabled =>
		ShowBounds || ShowPadding || ShowMargin || ShowZOrder || ShowHitTarget || ShowFocusPath
		|| ShowTabOrder;
}
