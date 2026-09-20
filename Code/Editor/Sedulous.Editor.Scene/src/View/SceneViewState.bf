namespace Sedulous.Editor.Scene;

/// The per scene view toggles a scene page keeps: what the viewport overlays.
struct SceneViewState
{
	public bool ShowGrid = true;
	public bool ShowLodOverlay = false;
	/// Edit time physics collider wireframes.
	public bool ShowColliders = false;

	public this() {}
	public this(bool showGrid, bool showLodOverlay, bool showColliders = false)
	{
		ShowGrid = showGrid;
		ShowLodOverlay = showLodOverlay;
		ShowColliders = showColliders;
	}
}
