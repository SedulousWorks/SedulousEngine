using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

// A scene page's overlays (Raptor's editor-gui spec, 5.3, layer 2): what the editor draws over the
// scene in its viewport's own debug list each frame (the lists clear every frame). The grid under the
// camera with the world's axes, the entity markers and the selection's boxes, the tools' gizmos and
// status, the component gizmos, the frame rate, the zoom readout and the orientation gizmo. Out of
// the page's class; the toggles are kept per scene (SceneViewPref).

/// One frame of what the overlays read. The page's, borrowed for the frame.
struct SceneOverlayFrame
{
	public Sedulous.Scene.Scene Scene = null;
	public Selection<Guid> Selection = null;
	public EditorCamera Camera = null;
	/// The viewport's render size.
	public uint32 Width = 0;
	public uint32 Height = 0;
	/// The pointer is over the viewport, at:
	public bool PointerOver = false;
	public float PointerX = 0.0f;
	public float PointerY = 0.0f;
	public ViewportToolManager Tools = null;
	public GizmoRendererRegistry ComponentGizmos = null;
	public float DeltaSeconds = 0.0f;
}

class SceneOverlays
{
	public SceneOverlaySettings Settings = .();

	/// Shown for a moment after each wheel zoom.
	private ZoomReadout mZoomReadout = new .() ~ delete _;
	// The frame rate readout samples half second windows, so it is legible rather than a blur.
	private double mFpsWindowSeconds = 0.0;
	private uint32 mFpsWindowFrames = 0;
	private String mFpsText = new .() ~ delete _;

	/// A wheel zoom happened: the measurement shows for a moment.
	public void Zoomed() => mZoomReadout.Zoomed();

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
		DrawFrameRate(dd, frame.DeltaSeconds);
		mZoomReadout.Advance(frame.DeltaSeconds);
		let opacity = mZoomReadout.Opacity;
		if (opacity > 0.0f)
			DrawZoomReadout(dd, frame, opacity);
		DrawViewGizmo(dd, frame);
	}

	/// The grid's spacing where the camera is now (by its distance from the grid's plane): what
	/// the grid draws and the zoom readout reports.
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

	/// The tools' gizmos and the active one's status, then the component gizmos: the full set for
	/// the selected entities, the opted-in renderers for the rest.
	private void DrawGizmos(DebugDraw dd, SceneOverlayFrame frame)
	{
		if (frame.Tools != null)
		{
			frame.Tools.Draw(dd);
			if (let active = frame.Tools.ActiveTool)
			{
				let status = active.StatusText;
				if (!status.IsEmpty)
					dd.DrawScreenText(12.0f, 12.0f, status, .(0.85f, 0.85f, 0.85f, 1.0f));
			}
		}
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

	/// The frame rate in the viewport's top right corner, clear of the tool status text in the
	/// top left. Sampled over half second windows of the page's update time, the rate the person
	/// editing sees rather than the application's.
	private void DrawFrameRate(DebugDraw dd, float dt)
	{
		if (!Settings.ShowFps)
		{
			mFpsWindowSeconds = 0.0;
			mFpsWindowFrames = 0;
			mFpsText.Clear();
			return;
		}
		mFpsWindowSeconds += (double)dt;
		mFpsWindowFrames++;
		if ((mFpsWindowSeconds >= 0.5) || mFpsText.IsEmpty)
		{
			FrameRateOverlay.Text(mFpsWindowSeconds, mFpsWindowFrames, mFpsText);
			mFpsWindowSeconds = 0.0;
			mFpsWindowFrames = 0;
		}
		dd.DrawScreenTextRight(12.0f, 12.0f, mFpsText, .(0.85f, 0.85f, 0.85f, 1.0f));
	}

	/// The measurement overlay while zooming, bottom left, at `opacity`: the focus distance and the
	/// grid cell over a scale bar of a round length at the focus. Clear of the tool status (top
	/// left) and the frame rate (top right).
	private void DrawZoomReadout(DebugDraw dd, SceneOverlayFrame frame, float opacity)
	{
		if (frame.Height == 0)
			return;
		let camera = frame.Camera;
		let height = (float)frame.Height;
		let bar = ZoomReadout.ScaleBarAt(camera.FocusDistance, camera.FovY, height);
		let focusText = scope String();
		ZoomReadout.FormatMetres(camera.FocusDistance, focusText);
		focusText.Append(" to focus");
		// The cell of the grid as drawn; whether the grid shows is the page's toggle.
		let cellText = scope String("grid cell ");
		ZoomReadout.FormatMetres(CurrentGridSpacing(camera).Spacing, cellText);
		let barText = ZoomReadout.FormatMetres(bar.Metres, .. scope String());

		const float cMargin = 12.0f;
		const float cPad = 6.0f;
		const float cLine = (float)DebugFont.cCharHeight + 6.0f;
		const float cGlyph = (float)DebugFont.cCharWidth;
		let textWidth = cGlyph * (float)Math.Max(focusText.Length, cellText.Length);
		let barWidth = bar.Pixels + 6.0f + cGlyph * (float)barText.Length;
		let width = Math.Max(textWidth, barWidth) + 2.0f * cPad;
		let boxHeight = 2.0f * cLine + 10.0f + 2.0f * cPad;
		let left = cMargin;
		let top = height - cMargin - boxHeight;
		dd.DrawScreenRect(left, top, width, boxHeight, .(0.0f, 0.0f, 0.0f, 0.45f * opacity));

		let ink = Color(0.85f, 0.85f, 0.85f, opacity);
		let x = left + cPad;
		dd.DrawScreenText(x, top + cPad, focusText, ink);
		dd.DrawScreenText(x, top + cPad + cLine, cellText, ink);
		// The bar: a line the length of its round measure, with end ticks, its length beside it.
		let barY = top + cPad + 2.0f * cLine + 4.0f;
		dd.DrawScreenRect(x, barY, bar.Pixels, 2.0f, ink);
		dd.DrawScreenRect(x, barY - 3.0f, 1.0f, 8.0f, ink);
		dd.DrawScreenRect(x + bar.Pixels - 1.0f, barY - 3.0f, 1.0f, 8.0f, ink);
		dd.DrawScreenText(x + bar.Pixels + 6.0f, barY - 3.0f, barText, ink);
	}

	/// The orientation gizmo: the axis tripod turning with the camera, back to front so a knob
	/// pointing at the viewer covers the arms and knobs behind it, the knob under the pointer lit.
	/// The positive axes have an arm from the centre, the negative ones a dimmer knob alone.
	private void DrawViewGizmo(DebugDraw dd, SceneOverlayFrame frame)
	{
		if (frame.Width == 0)
			return;
		let camera = frame.Camera;
		let gizmo = ViewGizmo.LayoutFor(camera.Right, camera.Up, camera.Forward, (float)frame.Width);
		let hovered = frame.PointerOver ? ViewGizmo.Hit(gizmo, frame.PointerX, frame.PointerY) : (int32)-1;
		const float cGlyph = (float)DebugFont.cCharWidth;
		const float cGlyphHeight = (float)DebugFont.cCharHeight;
		let half = 0.5f * ViewGizmo.cKnob;
		for (int32 i < 6)
		{
			let pole = gizmo.Poles[i];
			let color = ViewGizmo.ColorOf(pole, i == hovered);
			if (pole.Positive)
				dd.DrawScreenLine(gizmo.Center.X, gizmo.Center.Y, pole.Screen.X, pole.Screen.Y, color, 2.0f);
			dd.DrawScreenRect(pole.Screen.X - half, pole.Screen.Y - half, ViewGizmo.cKnob, ViewGizmo.cKnob, color);
			let label = ViewGizmo.Label(pole);
			let ink = pole.Positive ? Color(0.08f, 0.08f, 0.08f, 1.0f) : Color(0.9f, 0.9f, 0.9f, 1.0f);
			dd.DrawScreenText(pole.Screen.X - 0.5f * cGlyph * (float)label.Length, pole.Screen.Y - 0.5f * cGlyphHeight, label, ink);
		}
		// The centre: a click switches the projection; under the tripod, which one is on.
		let overCentre = frame.PointerOver && ViewGizmo.HitCentre(gizmo, frame.PointerX, frame.PointerY);
		let c = 0.5f * ViewGizmo.cCentre;
		let centre = overCentre ? Color(1.0f, 1.0f, 1.0f, 1.0f) : Color(0.75f, 0.75f, 0.75f, 1.0f);
		dd.DrawScreenRect(gizmo.Center.X - c, gizmo.Center.Y - c, ViewGizmo.cCentre, ViewGizmo.cCentre, centre);
		let projection = ViewGizmo.ProjectionLabel(camera.Orthographic);
		dd.DrawScreenText(gizmo.Center.X - 0.5f * cGlyph * (float)projection.Length,
			gizmo.Center.Y + ViewGizmo.cArm + ViewGizmo.cKnob, projection, .(0.85f, 0.85f, 0.85f, 1.0f));
	}
}
