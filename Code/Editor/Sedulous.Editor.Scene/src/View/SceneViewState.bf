namespace Sedulous.Editor.Scene;

/// The per scene view toggles a scene page keeps: what the viewport overlays.
struct SceneViewState
{
	public bool ShowGrid = true;
	public bool ShowLodOverlay = false;
	/// Edit time physics collider wireframes.
	public bool ShowColliders = false;
	/// The origin cross on every entity. Off by default: the viewport shows the scene, and the
	/// selected entity keeps its own cross; the Overlays menu turns them on.
	public bool ShowMarkers = false;
	/// The frame rate readout in the viewport's top right corner.
	public bool ShowFps = false;
	/// The plane the grid lies on.
	public GridPlane GridPlane = .XZ;
	/// Debug lines instead of the shader grid, kept to compare the two.
	public bool GridLines = false;

	public this() {}
	public this(bool showGrid, bool showLodOverlay, bool showColliders = false,
		bool showMarkers = false, bool showFps = false)
	{
		ShowGrid = showGrid;
		ShowLodOverlay = showLodOverlay;
		ShowColliders = showColliders;
		ShowMarkers = showMarkers;
		ShowFps = showFps;
	}
}
