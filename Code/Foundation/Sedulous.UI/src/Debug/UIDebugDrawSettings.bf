namespace Sedulous.UI;

/// Flags controlling which debug overlays are drawn after the normal render pass.
/// Zero overhead when all flags are false.
public struct UIDebugDrawSettings
{
	public bool ShowBounds;           // red outline around every view
	public bool ShowPadding;          // green fill for padding region
	public bool ShowMargin;           // orange fill for margin region
	public bool ShowDrawablePadding;  // distinct color for drawable-contributed padding
	public bool ShowZOrder;           // numbered overlay showing draw order
	public bool ShowHitTarget;        // highlight view under cursor (Phase 3)
	public bool ShowFocusPath;        // chain from focused view to root (Phase 3)
	public bool ShowTabOrder;         // numbered focus arrows (Phase 3)

	public bool AnyEnabled =>
		ShowBounds || ShowPadding || ShowMargin || ShowDrawablePadding ||
		ShowZOrder || ShowHitTarget || ShowFocusPath || ShowTabOrder;
}
