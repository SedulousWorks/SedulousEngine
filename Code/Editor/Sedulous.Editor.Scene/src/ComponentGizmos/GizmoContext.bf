using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Editor.Scene;

/// What a component gizmo draws with and against. Everything borrowed; the registry fills
/// in the per entity fields as it walks.
class GizmoContext
{
	public DebugDraw Debug = null;
	public Sedulous.Scene.Scene Scene = null;
	public Float3 CameraPosition = .Zero;
	/// The view the LOD overlay judges coverage against; null hides the overlay.
	public ViewCamera* ViewCamera = null;
	public bool LodOverlay = false;
	/// The editor's Show Colliders toggle; the runtime's debug draw is separate.
	public bool ShowColliders = false;
	/// Set per entity by the registry: an inactive entity draws dimmed, not skipped.
	public bool EntityEffectivelyActive = true;
}
