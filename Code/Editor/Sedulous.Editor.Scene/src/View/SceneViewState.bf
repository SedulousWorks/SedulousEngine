namespace Sedulous.Editor.Scene;

/// The per scene view toggles a scene page keeps: what the viewport overlays.
struct SceneViewState
{
	public bool ShowGrid = true;
	public bool ShowLodOverlay = false;
	/// Edit time physics collider wireframes.
	public bool ShowColliders = false;
	/// The origin cross on every entity; off for a scene with thousands of them.
	public bool ShowMarkers = true;

	public this() {}
	public this(bool showGrid, bool showLodOverlay, bool showColliders = false,
		bool showMarkers = true)
	{
		ShowGrid = showGrid;
		ShowLodOverlay = showLodOverlay;
		ShowColliders = showColliders;
		ShowMarkers = showMarkers;
	}
}
