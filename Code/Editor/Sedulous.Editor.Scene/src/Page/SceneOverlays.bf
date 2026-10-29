using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

// A scene page's overlays (Raptor's editor-gui spec, 5.3, layer 2): what the editor draws into the
// scene in its viewport's own debug list each frame (the lists clear every frame). The grid under the
// camera with the world's axes, the entity markers and the selection's boxes, the tools' gizmos, the
// component gizmos. Out of the page's class; the toggles are kept per scene (SceneViewPref). What is
// written rather than drawn in the scene (the stats, the tool's status, the zoom readout, the view
// gizmo) is the HUD's, on the GUI (layer 5).

/// One frame of what the overlays read. The page's, borrowed for the frame.
struct SceneOverlayFrame
{
	public Sedulous.Scene.Scene Scene = null;
	public Selection<Guid> Selection = null;
	public EditorCamera Camera = null;
	/// The viewport's render size.
	public uint32 Width = 0;
	public uint32 Height = 0;
	public ViewportToolManager Tools = null;
	public GizmoRendererRegistry ComponentGizmos = null;
}

class SceneOverlays
{
	public SceneOverlaySettings Settings = .();

	/// Everything, in order, into `dd`.
	public void Draw(DebugDraw dd, SceneOverlayFrame frame)
	{
		if ((frame.Scene == null) || (frame.Camera == null))
			return;
		if (Settings.ShowGrid)
		{
			DrawGrid(dd, frame.Camera);
			dd.DrawLine(.Zero, .(1, 0, 0), .(0.9f, 0.2f, 0.2f, 1.0f));
			dd.DrawLine(.Zero, .(0, 1, 0), .(0.2f, 0.9f, 0.2f, 1.0f));
			dd.DrawLine(.Zero, .(0, 0, 1), .(0.2f, 0.4f, 0.95f, 1.0f));
		}
		DrawEntityMarkers(dd, frame);
		DrawGizmos(dd, frame);
	}

	/// The grid's spacing where the camera is now (by its distance from the grid's plane): what
	/// the grid draws and the HUD's zoom readout reports.
	public GridSpacing CurrentGridSpacing(EditorCamera camera) => SceneGrid.SpacingFor(GridViewHeight(camera));

	/// How high the camera is over the grid's plane, for its spacing: the eye's height in
	/// perspective; under orthographic, the pivot's distance (what the view spans), since an
	/// orthographic eye may stand level with the plane and still see across it.
	private float GridViewHeight(EditorCamera camera)
	{
		if (camera.Orthographic)
			return camera.FocusDistance;
		return Math.Abs(Dot(camera.Position, SceneGrid.AxesOf(Settings.GridPlane).Normal));
	}

	/// The grid on the chosen plane: the shader grid, or debug lines when GridLines.
	private void DrawGrid(DebugDraw dd, EditorCamera camera)
	{
		let axes = SceneGrid.AxesOf(Settings.GridPlane);
		let height = GridViewHeight(camera);
		let step = SceneGrid.SpacingFor(height);
		// The camera's foot on the plane: the grid is centred under it, wherever it flies.
		let foot = camera.Position - axes.Normal * Dot(camera.Position, axes.Normal);
		if (!Settings.GridLines)
		{
			var grid = GridPlaneDesc();
			grid.Origin = foot;
			grid.FadeDistance = SceneGrid.FadeDistance(height);
			grid.Extent = grid.FadeDistance;
			grid.AxisU = axes.U;
			grid.AxisV = axes.V;
			grid.Spacing = step.Spacing;
			grid.Blend = step.Blend;
			grid.CameraPosition = camera.Position;
			dd.DrawGridPlane(grid);
			return;
		}
		// The line grid, to compare: the same spacing, every tenth line brighter, a square a
		// hundred cells each way snapped to the coarse spacing under the camera (so it does not
		// swim), no fade and no blend between decades.
		const int32 cHalfCells = 100;
		let coarse = step.Spacing * 10.0f;
		let cu = Math.Floor(Dot(foot, axes.U) / coarse) * coarse;
		let cv = Math.Floor(Dot(foot, axes.V) / coarse) * coarse;
		let half = step.Spacing * (float)cHalfCells;
		// sRGB, like every colour: a light grey that stays clear of the backdrop.
		let minor = Color(0.63f, 0.63f, 0.65f, 0.35f);
		let major = Color(0.63f, 0.63f, 0.65f, 1.0f);
		for (int32 i = -cHalfCells; i <= cHalfCells; i++)
		{
			let t = (float)i * step.Spacing;
			let color = (i % 10 == 0) ? major : minor;
			let alongV = axes.U * (cu + t);
			let alongU = axes.V * (cv + t);
			dd.DrawLine(alongV + axes.V * (cv - half), alongV + axes.V * (cv + half), color);
			dd.DrawLine(alongU + axes.U * (cu - half), alongU + axes.U * (cu + half), color);
		}
	}

	/// A small cross at every entity (with Markers on; the selection keeps its own), and the
	/// selection's bounds: what the scene's systems measure an entity as (meshes, colliders), the
	/// box F frames; a small one at its origin when none does. Empty entities have no renderable,
	/// so the cross is their visual anchor.
	private void DrawEntityMarkers(DebugDraw dd, SceneOverlayFrame frame)
	{
		if (frame.Selection == null)
			return;
		let selection = frame.Selection;
		let scene = frame.Scene;
		let showMarkers = Settings.ShowMarkers;
		scene.ForEachEntity(scope [&](e) =>
		{
			let world = scene.GetWorldMatrix(e);
			let p = Float3(world.M[3][0], world.M[3][1], world.M[3][2]);
			let selected = selection.Contains(scene.GetEntityId(e));
			if (!selected && !showMarkers)
				return; // the Markers toggle: an unselected origin draws nothing
			let s = 0.25f;
			let color = selected ? Color(1.0f, 0.85f, 0.25f, 1.0f) : Color(0.75f, 0.75f, 0.80f, 1.0f);
			dd.DrawLine(p - Float3(s, 0, 0), p + Float3(s, 0, 0), color);
			dd.DrawLine(p - Float3(0, s, 0), p + Float3(0, s, 0), color);
			dd.DrawLine(p - Float3(0, 0, s), p + Float3(0, 0, s), color);
			if (!selected)
				return;
			if (scene.EntityWorldBounds(e, let bounds))
			{
				dd.DrawWireBoxCenter(bounds.Center(), bounds.Extents(), color);
				return;
			}
			dd.DrawWireBoxCenter(p, .(0.35f, 0.35f, 0.35f), color);
		});
	}

	/// The tools' gizmos, then the component gizmos: the full set for the selected entities, the
	/// opted-in renderers for the rest.
	private void DrawGizmos(DebugDraw dd, SceneOverlayFrame frame)
	{
		if (frame.Tools != null)
			frame.Tools.Draw(dd);
		if ((frame.ComponentGizmos == null) || (frame.Selection == null))
			return;
		let camera = frame.Camera;
		let ctx = scope GizmoContext();
		ctx.Debug = dd;
		ctx.Scene = frame.Scene;
		ctx.CameraPosition = camera.Position;
		// The viewport's camera for the LOD overlay's per view pick: the same matrices the render
		// path builds (aspect from the render target when it has a size).
		var gizmoCamera = ViewCamera();
		gizmoCamera.View = Float4x4.LookAtRH(camera.DrawEye, camera.DrawEye + camera.Forward, camera.Up);
		let aspect = (frame.Height > 0) ? (float)frame.Width / (float)frame.Height : 16.0f / 9.0f;
		gizmoCamera.Projection = camera.Projection(aspect);
		gizmoCamera.Position = camera.Position;
		gizmoCamera.FarZ = camera.DrawFar;
		gizmoCamera.PullBack = camera.DrawPullBack;
		ctx.ViewCamera = &gizmoCamera;
		ctx.LodOverlay = Settings.ShowLodOverlay;
		ctx.ShowColliders = Settings.ShowColliders;
		let selection = frame.Selection;
		let scene = frame.Scene;
		let gizmos = frame.ComponentGizmos;
		scene.ForEachEntity(scope [&](e) =>
		{
			gizmos.DrawEntity(e, selection.Contains(scene.GetEntityId(e)), ctx);
		});
	}
}
