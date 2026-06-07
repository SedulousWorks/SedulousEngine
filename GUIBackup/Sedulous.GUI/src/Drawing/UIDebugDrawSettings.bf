namespace Sedulous.GUI;

/// Flags controlling which debug overlays are drawn after the normal render pass.
public struct UIDebugDrawSettings
{
	public bool ShowBounds;
	public bool ShowPadding;
	public bool ShowMargin;
	public bool ShowZOrder;
	public bool ShowHitTarget;
	public bool ShowFocusPath;
	public bool ShowTabOrder;

	public bool AnyEnabled =>
		ShowBounds || ShowPadding || ShowMargin ||
		ShowZOrder || ShowHitTarget || ShowFocusPath || ShowTabOrder;
}
