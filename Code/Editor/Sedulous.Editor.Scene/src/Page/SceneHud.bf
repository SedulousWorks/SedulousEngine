using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.VG;
using Sedulous.GUI;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Camera;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Scene;

// The scene view's HUD (Raptor's editor-gui spec, 5.3, layer 5, part 2): GUI over the viewport in
// fixed zones, so nothing meets in a corner, in the editor's fonts rather than the debug draw's
// bitmap one.
//   - top start, the chips (ruling 22), each saying what is on and in the accent while it is off
//     its default: the projection (perspective or orthographic, the six axis views), the shading
//     (Lit, Unlit, the debug terms, the graph's textures through the picker, the effects as what is
//     on, MSAA; ruling 21), the overlays (the grid and its plane, markers, colliders, the LOD tint,
//     the stats);
//   - top end, the stats (frames a second and their time) and the view gizmo, which turns with the
//     camera: a knob looks along its axis, the centre switches the projection (which one is on, the
//     projection chip says);
//   - bottom start, the zoom readout a moment after a wheel zoom, and the active tool's status (the
//     select tool's in parts: its mode, its space, its snap, what is selected).
// The page hands in what the HUD shows and changes; the scene's own overlays (the grid, the gizmos)
// stay drawn into the view.

/// The tripod: six knobs turning with the camera, the positive ones on arms, the centre the
/// projection switch, on a disc (its sheet's background). Its letters are labels; the knobs and
/// arms are drawn.
class ViewGizmoView : UIWidget
{
	private const float cSide = 2.0f * (ViewGizmo.cArm + 0.5f * ViewGizmo.cKnob) + 4.0f;

	/// A press on a knob (its axis) or the centre.
	public delegate void(Float3 axis) OnAxis ~ delete _;
	public delegate void() OnCentre ~ delete _;

	private ViewGizmoLayout mLayout;
	// Ours, besides the tree's.
	private Label[6] mLabels;
	private Float3[3] mBasis;
	private bool mOrthographic = false;
	private bool mShown = false;
	// A knob, 6 the centre; -1 none.
	private int32 mHovered = -1;

	public this()
	{
		AddClass("hud-gizmo");
		for (int i < 6)
		{
			let label = new Label();
			label.AddClass("axis-label");
			label.SetTextAlignment(.Center, .Middle);
			label.HitTestVisible = false;
			AddChild(label);
			mLabels[i] = label;
		}
		Tooltip = "Click an axis to look along it; the centre switches perspective and orthographic";
	}

	public ~this()
	{
		for (let label in mLabels)
			label.ReleaseRef();
	}

	public ViewGizmoLayout Layout => mLayout;

	/// The camera's basis now; laid out again when it turned.
	public void Show(Float3 right, Float3 up, Float3 forward, bool orthographic)
	{
		if (mShown && (right == mBasis[0]) && (up == mBasis[1]) && (forward == mBasis[2]) && (orthographic == mOrthographic))
			return;
		mBasis[0] = right;
		mBasis[1] = up;
		mBasis[2] = forward;
		mOrthographic = orthographic;
		mShown = true;
		RequestLayout();
		Invalidate();
	}

	/// Presses at a point in its own space, as the pointer does (for tests).
	public bool PressAt(Float2 local)
	{
		let hit = ViewGizmo.Hit(mLayout, local.X, local.Y);
		if (hit >= 0)
		{
			if (OnAxis != null)
				OnAxis(mLayout.Poles[hit].Axis);
			return true;
		}
		if (ViewGizmo.HitCentre(mLayout, local.X, local.Y))
		{
			if (OnCentre != null)
				OnCentre();
			return true;
		}
		return false;
	}

	public override Float2 MeasureContent(Float2 available) => .(cSide, cSide);

	public override void OnLayout()
	{
		let content = ContentBounds;
		mLayout = ViewGizmo.LayoutAround(mBasis[0], mBasis[1], mBasis[2], .(content.X + 0.5f * cSide, content.Y + 0.5f * cSide));
		let half = 0.5f * ViewGizmo.cKnob;
		for (int i < 6)
		{
			let pole = mLayout.Poles[i];
			mLabels[i].Text = ViewGizmo.Label(pole);
			if (pole.Positive)
				mLabels[i].RemoveClass("negative");
			else
				mLabels[i].AddClass("negative");
			mLabels[i].Arrange(Rect(pole.Screen.X - half, pole.Screen.Y - half, ViewGizmo.cKnob, ViewGizmo.cKnob));
		}
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		// Back to front, so a knob toward the viewer covers the arms and knobs behind it.
		for (int32 i < 6)
		{
			let pole = mLayout.Poles[i];
			let color = ViewGizmo.ColorOf(pole, i == mHovered);
			if (pole.Positive)
			{
				let arm = scope PathBuilder();
				arm.MoveTo(mLayout.Center.X, mLayout.Center.Y);
				arm.LineTo(pole.Screen.X, pole.Screen.Y);
				let path = arm.ToPath();
				ctx.VG.StrokePath(path, color, StrokeStyle(2.0f, .Round, .Round));
				delete path;
			}
			ctx.VG.FillCircle(pole.Screen, 0.5f * ViewGizmo.cKnob, color);
		}
		let centre = (mHovered == 6) ? Color(1.0f, 1.0f, 1.0f, 1.0f) : Color(0.75f, 0.75f, 0.75f, 1.0f);
		ctx.VG.FillCircle(mLayout.Center, 0.5f * ViewGizmo.cCentre, centre);
	}

	protected override void OnMouseDown(MouseEvent e)
	{
		if (e.Button != .Left)
			return;
		if (PressAt(ConvertToNodeSpace(e.Position)))
			e.Handled = true;
	}

	protected override void OnMouseMove(MouseEvent e)
	{
		Hover(ConvertToNodeSpace(e.Position));
	}

	protected override void OnMouseLeave(MouseEvent e)
	{
		if (mHovered != -1)
		{
			mHovered = -1;
			Invalidate();
		}
	}

	private void Hover(Float2 local)
	{
		var hovered = ViewGizmo.Hit(mLayout, local.X, local.Y);
		if ((hovered < 0) && ViewGizmo.HitCentre(mLayout, local.X, local.Y))
			hovered = 6;
		if (hovered != mHovered)
		{
			mHovered = hovered;
			Invalidate();
		}
	}
}

/// The zoom readout's bar: a round measure's length with its end ticks.
class ScaleBarView : UIWidget
{
	private float mPixels = 0.0f;

	public this()
	{
		HitTestVisible = false;
	}

	public void SetLength(float pixels)
	{
		if (pixels != mPixels)
		{
			mPixels = pixels;
			RequestLayout();
		}
	}

	public override Float2 MeasureContent(Float2 available) => .(mPixels, 8.0f);

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		let ink = TextColor;
		let y = localBounds.Y + 0.5f * localBounds.Height;
		ctx.VG.FillRect(.(localBounds.X, y - 1.0f, mPixels, 2.0f), ink);
		ctx.VG.FillRect(.(localBounds.X, localBounds.Y, 1.0f, localBounds.Height), ink);
		ctx.VG.FillRect(.(localBounds.X + mPixels - 1.0f, localBounds.Y, 1.0f, localBounds.Height), ink);
	}
}

/// What a scene HUD asks of its page. The hooks are its own; the rest is borrowed and outlives it.
class SceneHudServices
{
	public EditorContext Context = null;
	public SceneEditContext Edit = null;
	public EditorCamera Camera = null;
	public SceneOverlays Overlays = null;
	public ViewPostOverride* Post = null;
	public ViewDebugView DebugView = null;
	public ViewportToolManager Tools = null;
	/// The default tool: its status in parts.
	public IViewportTool SelectTool = null;
	public delegate GizmoController() Gizmos ~ delete _;
	/// The graph's textures of the last frame, appended (the caller deletes them); null: none to
	/// offer.
	public delegate void(List<DebugResourceInfo> outRows) DebugResources ~ delete _;
	/// Opens the picker for a request; OWNERSHIP of the request transfers.
	public delegate void(PickerRequest request) Pick ~ delete _;
	/// An overlay changed: the page keeps its view state.
	public delegate void() OverlaysChanged ~ delete _;
}

class SceneHud
{
	public enum Projection : uint8
	{
		Perspective,
		Orthographic,
	}

	// The debug terms the shading's submenu offers (Albedo is Unlit, above them).
	private static (ViewDebugSemantic Semantic, String Label)[6] sTerms = .(
		(.Normal, "Normals"), (.Roughness, "Roughness"), (.Metallic, "Metallic"),
		(.Cascades, "Shadow Cascades"), (.ClusterHeat, "Light Clusters"), (.Overbright, "Overbright"));
	// The axis views, each the axis it looks along from.
	private static (Float3 Axis, String Label)[6] sAxisViews = .(
		(.(0, 1, 0), "Top"), (.(0, -1, 0), "Bottom"), (.(0, 0, 1), "Front"),
		(.(0, 0, -1), "Back"), (.(1, 0, 0), "Right"), (.(-1, 0, 0), "Left"));

	private class Chip
	{
		/// The page's, which outlives the HUD.
		public ButtonBase Button = null;
		public String Text = new .() ~ delete _;
		public bool On = false;
	}

	// A menu item whose check follows a state, asked again each frame.
	private class Checked
	{
		/// The menu's, which the chip keeps.
		public MenuItem Item = null;
		public delegate bool() On ~ delete _;
	}

	private SceneHudServices mServices ~ delete _;
	private Chip mProjection = new .() ~ delete _;
	private Chip mShading = new .() ~ delete _;
	private Chip mOverlays = new .() ~ delete _;
	private List<Checked> mChecks = new .() ~ DeleteContainerAndItems!(_);
	// The page's, which outlive the HUD.
	private Label mStats = null;
	private Node mZoomBox = null;
	private Label mZoomFocus = null;
	private Label mZoomCell = null;
	private Label mZoomLength = null;
	private Node mStatus = null;
	private Image mStatusIcon = null;
	private Label[4] mStatusParts;
	// Ours, besides the tree's.
	private ViewGizmoView mGizmo = null ~ { if (_ != null) _.ReleaseRef(); };
	private ScaleBarView mZoomBar = null ~ { if (_ != null) _.ReleaseRef(); };
	private ZoomReadout mZoom = new .() ~ delete _;
	private double mStatsSeconds = 0.0;
	private uint32 mStatsFrames = 0;
	private String mStatsText = new .() ~ delete _;

	/// The HUD's zones (the markup's: `chip-projection`, `chip-shading`, `chip-overlays`,
	/// `hud-stats`, `hud-top-end`, `hud-zoom` ..., found by `find`). It takes `services`.
	public this(SceneHudServices services, delegate Node(StringView id) find)
	{
		mServices = services;
		mProjection.Button = find("chip-projection") as ButtonBase;
		if (let menu = mProjection.Button as ToolMenuButton)
			BuildProjection(menu.Menu);
		mShading.Button = find("chip-shading") as ButtonBase;
		if (let menu = mShading.Button as ToolMenuButton)
			BuildShading(menu.Menu);
		mOverlays.Button = find("chip-overlays") as ButtonBase;
		if (let menu = mOverlays.Button as ToolMenuButton)
			BuildOverlays(menu.Menu);
		mStats = find("hud-stats") as Label;
		if (let zone = find("hud-top-end"))
		{
			mGizmo = new ViewGizmoView();
			mGizmo.OnAxis = new (axis) => { LookAlong(axis); };
			mGizmo.OnCentre = new () =>
				{
					if (mServices.Camera != null)
						SetProjection(mServices.Camera.Orthographic ? .Perspective : .Orthographic);
				};
			zone.AddChild(mGizmo);
		}
		mZoomBox = find("hud-zoom");
		mZoomFocus = find("hud-zoom-focus") as Label;
		mZoomCell = find("hud-zoom-cell") as Label;
		mZoomLength = find("hud-zoom-length") as Label;
		if (let row = find("hud-zoom-bar"))
		{
			mZoomBar = new ScaleBarView();
			row.AddChildAt(mZoomBar, 0);
		}
		mStatus = find("hud-status");
		mStatusIcon = find("hud-status-icon") as Image;
		StringView[4] parts = .("hud-status-mode", "hud-status-space", "hud-status-snap", "hud-status-selection");
		for (int i < 4)
			mStatusParts[i] = find(parts[i]) as Label;
		Update(0.0f, 0);
	}

	/// A wheel zoom happened: the readout shows for a moment.
	public void Zoomed() => mZoom.Zoomed();

	/// Once a frame: everything as it is now (`dt` the frame's time, for the stats and the
	/// readout's fade; the view's height in pixels for its scale bar).
	public void Update(float dt, uint32 viewHeight)
	{
		for (let check in mChecks)
		{
			if (check.On == null)
				continue;
			let on = check.On();
			if (check.Item.Checked != on)
				check.Item.SetCheckedSilently(on);
		}
		if (let camera = mServices.Camera)
		{
			let axis = AxisViewName();
			if (!axis.IsEmpty)
				ShowChip(mProjection, axis, true);
			else
				ShowChip(mProjection, camera.Orthographic ? "Orthographic" : "Perspective", camera.Orthographic);
			if (mGizmo != null)
				mGizmo.Show(camera.Right, camera.Up, camera.Forward, camera.Orthographic);
		}
		if (let debug = mServices.DebugView)
		{
			let lit = debug.Resource.IsEmpty && (debug.Semantic == .Off);
			ShowChip(mShading, !debug.Resource.IsEmpty ? (StringView)debug.Resource : NameOfTerm(debug.Semantic), !lit);
		}
		ShowChip(mOverlays, "Overlays", false);
		UpdateStats(dt);
		UpdateStatus();
		UpdateZoom(dt, viewHeight);
	}

	// === What the menus do, by name (the menus call these; so do tests) ===

	public void SetProjection(Projection projection)
	{
		if (mServices.Camera != null)
			mServices.Camera.SetOrthographic(projection == .Orthographic);
	}

	/// Looks along `axis` from its side, as the gizmo's knob does.
	public void LookAlong(Float3 axis)
	{
		let camera = mServices.Camera;
		if (camera == null)
			return;
		ViewGizmo.SnapAngles(axis, camera.Yaw, let yaw, let pitch);
		camera.AutoOrthographic = (mServices.Context != null) && EditorUiSettings.AutoOrthographicViews(mServices.Context.UserEditorSettings);
		camera.SnapToAxis(yaw, pitch);
	}

	/// Lit (no debug term), Unlit (Albedo), or a debug term.
	public void SetShading(ViewDebugSemantic semantic)
	{
		if (mServices.DebugView == null)
			return;
		mServices.DebugView.Resource.Clear(); // a term and a texture are one or the other
		mServices.DebugView.Semantic = semantic;
	}

	public void ShowTexture(StringView name)
	{
		let debug = mServices.DebugView;
		if (debug == null)
			return;
		debug.Resource.Set(name);
		debug.Semantic = .Off;
		// A depth texture shows as distance between the editor camera's planes.
		if (mServices.Camera != null)
		{
			debug.NearZ = mServices.Camera.NearZ;
			debug.FarZ = mServices.Camera.DrawFar;
		}
	}

	/// The graph's textures in the picker, by their pass.
	public void OpenTextures()
	{
		if ((mServices.DebugResources == null) || (mServices.Pick == null))
			return;
		let rows = scope List<DebugResourceInfo>();
		defer { ClearAndDeleteItems!(rows); }
		mServices.DebugResources(rows);
		let request = new PickerRequest();
		request.Placeholder.Set("Search render textures");
		request.EmptyTitle.Set("No render textures yet");
		request.EmptyText.Set("The renderer lists a frame's textures once it has drawn one.");
		if (mServices.DebugView != null)
			request.Current.Set(mServices.DebugView.Resource);
		// By their pass, in the order the frame made them; a multisampled one is shown by its
		// resolved twin (a blit cannot read it).
		let passes = scope List<String>();
		defer { ClearAndDeleteItems!(passes); }
		for (let row in rows)
		{
			if (row.Samples > 1)
				continue;
			let pass = PassOf(row.Name, .. scope String());
			var known = false;
			for (let seen in passes)
				known = known || (seen == pass);
			if (!known)
				passes.Add(new String(pass));
		}
		for (let pass in passes)
		{
			for (let row in rows)
			{
				if ((row.Samples > 1) || (PassOf(row.Name, .. scope String()) != pass))
					continue;
				let detail = scope String()..AppendF("{}x{}", row.Width, row.Height);
				if (row.IsDepth)
					detail.Append("  depth");
				let item = request.Add(row.Name, row.Name, pass, detail);
				item.Glyph.Set("Editor/Icons/texture.svg");
			}
		}
		request.OnPicked = new (key) =>
			{
				if (!key.IsEmpty)
					ShowTexture(key);
			};
		mServices.Pick(request);
	}

	// === For tests ===

	public StringView ChipText(StringView id) => ChipOf(id).Text;
	public bool ChipOn(StringView id) => ChipOf(id).On;

	public Menu ChipMenu(StringView id)
	{
		let menu = ChipOf(id).Button as ToolMenuButton;
		return (menu != null) ? menu.Menu : null;
	}

	/// The status's shown parts, by " | ", appended.
	public void StatusText(String outText)
	{
		if ((mStatus == null) || !mStatus.Displayed)
			return;
		for (let label in mStatusParts)
		{
			if ((label != null) && label.Displayed)
			{
				if (!outText.IsEmpty)
					outText.Append(" | ");
				outText.Append(label.Text);
			}
		}
	}

	public ViewGizmoView Gizmo => mGizmo;
	public bool ZoomShown => (mZoomBox != null) && mZoomBox.Displayed;
	public bool StatsShown => (mStats != null) && mStats.Displayed;

	// === Building ===

	private Chip ChipOf(StringView id)
	{
		if (id == "chip-projection")
			return mProjection;
		if (id == "chip-shading")
			return mShading;
		return mOverlays;
	}

	// A checkable item; `on` and `pick` are taken.
	private MenuItem AddCheck(Menu menu, StringView label, delegate bool() on, delegate void() pick)
	{
		let item = menu.AddCheckItem(label, (on != null) ? on() : false, new (isOn) => { pick(); } ~ delete pick);
		let check = new Checked();
		check.Item = item;
		check.On = on;
		mChecks.Add(check);
		return item;
	}

	private void BuildProjection(Menu menu)
	{
		let camera = mServices.Camera;
		if (camera == null)
			return;
		AddCheck(menu, "Perspective", new [=camera] () => !camera.Orthographic, new () => { SetProjection(.Perspective); });
		AddCheck(menu, "Orthographic", new [=camera] () => camera.Orthographic, new () => { SetProjection(.Orthographic); });
		menu.AddSeparator();
		for (let view in sAxisViews)
		{
			let axis = view.Axis;
			menu.AddItem(view.Label, new [=this, =axis] () => { LookAlong(axis); });
		}
	}

	private void BuildShading(Menu menu)
	{
		let debug = mServices.DebugView;
		let post = mServices.Post;
		if ((debug == null) || (post == null))
			return;
		AddCheck(menu, "Lit", new [=debug] () => debug.Resource.IsEmpty && (debug.Semantic == .Off), new () => { SetShading(.Off); });
		AddCheck(menu, "Unlit", new [=debug] () => debug.Resource.IsEmpty && (debug.Semantic == .Albedo), new () => { SetShading(.Albedo); });
		let terms = menu.AddSubMenu("Debug View");
		for (let term in sTerms)
		{
			let semantic = term.Semantic;
			AddCheck(terms, term.Label, new [=debug, =semantic] () => debug.Resource.IsEmpty && (debug.Semantic == semantic), new [=this, =semantic] () => { SetShading(semantic); });
		}
		let textures = AddCheck(menu, "Render Textures...", new [=debug] () => !debug.Resource.IsEmpty, new () => { OpenTextures(); });
		textures.Enabled = (mServices.DebugResources != null) && (mServices.Pick != null);
		menu.AddSeparator();
		let effects = menu.AddSubMenu("Effects");
		AddCheck(effects, "Post-processing", new [=post] () => !post.DisablePost, new [=post] () => { post.DisablePost = !post.DisablePost; });
		effects.AddSeparator();
		AddCheck(effects, "Bloom", new [=post] () => !post.DisableBloom, new [=post] () => { post.DisableBloom = !post.DisableBloom; });
		AddCheck(effects, "Ambient Occlusion", new [=post] () => !post.DisableAo, new [=post] () => { post.DisableAo = !post.DisableAo; });
		AddCheck(effects, "Reflections (SSR)", new [=post] () => !post.DisableSsr, new [=post] () => { post.DisableSsr = !post.DisableSsr; });
		AddCheck(effects, "Global Illumination (SSGI)", new [=post] () => !post.DisableSsgi, new [=post] () => { post.DisableSsgi = !post.DisableSsgi; });
		AddCheck(effects, "Anti-aliasing", new [=post] () => !post.DisableAa, new [=post] () => { post.DisableAa = !post.DisableAa; });
		effects.AddSeparator();
		AddCheck(effects, "Frustum Culling", new [=post] () => !post.DisableCulling, new [=post] () => { post.DisableCulling = !post.DisableCulling; });
		let msaa = menu.AddSubMenu("MSAA");
		for (let level in MsaaLevels.All)
		{
			let samples = (uint8)level.Samples;
			AddCheck(msaa, level.Label, new [=post, =samples] () => (samples <= 1) ? (post.MsaaOverride <= 1) : (post.MsaaOverride == samples),
				new [=post, =samples] () => { post.MsaaOverride = samples; });
		}
	}

	private void BuildOverlays(Menu menu)
	{
		let overlays = mServices.Overlays;
		if (overlays == null)
			return;
		AddCheck(menu, "Grid", new [=overlays] () => overlays.Settings.ShowGrid, new [=this, =overlays] () => { overlays.Settings.ShowGrid = !overlays.Settings.ShowGrid; OverlaysChanged(); });
		let planes = menu.AddSubMenu("Grid Plane");
		(GridPlane Plane, String Label)[3] choices = .((.XZ, "XZ (ground)"), (.XY, "XY"), (.YZ, "YZ"));
		for (let choice in choices)
		{
			let value = choice.Plane;
			AddCheck(planes, choice.Label, new [=overlays, =value] () => overlays.Settings.GridPlane == value,
				new [=this, =overlays, =value] () => { overlays.Settings.GridPlane = value; OverlaysChanged(); });
		}
		AddCheck(menu, "Entity Markers", new [=overlays] () => overlays.Settings.ShowMarkers, new [=this, =overlays] () => { overlays.Settings.ShowMarkers = !overlays.Settings.ShowMarkers; OverlaysChanged(); });
		AddCheck(menu, "Colliders", new [=overlays] () => overlays.Settings.ShowColliders, new [=this, =overlays] () => { overlays.Settings.ShowColliders = !overlays.Settings.ShowColliders; OverlaysChanged(); });
		AddCheck(menu, "LOD Tint", new [=overlays] () => overlays.Settings.ShowLodOverlay, new [=this, =overlays] () => { overlays.Settings.ShowLodOverlay = !overlays.Settings.ShowLodOverlay; OverlaysChanged(); });
		menu.AddSeparator();
		AddCheck(menu, "Stats", new [=overlays] () => overlays.Settings.ShowFps, new [=this, =overlays] () => { overlays.Settings.ShowFps = !overlays.Settings.ShowFps; OverlaysChanged(); });
	}

	private void OverlaysChanged()
	{
		if (mServices.OverlaysChanged != null)
			mServices.OverlaysChanged();
	}

	// === Showing ===

	private void ShowChip(Chip chip, StringView text, bool on)
	{
		if (chip.Button == null)
			return;
		if (chip.Text != text)
		{
			chip.Button.Text = text;
			chip.Text.Set(text);
		}
		if (chip.On != on)
		{
			if (on)
				chip.Button.AddClass("on");
			else
				chip.Button.RemoveClass("on");
			chip.On = on;
		}
	}

	private StringView AxisViewName()
	{
		let camera = mServices.Camera;
		if (camera == null)
			return default;
		let forward = camera.Forward;
		for (let view in sAxisViews)
		{
			if (Dot(forward, view.Axis) < -0.9999f) // looking along it from its side
				return view.Label;
		}
		return default;
	}

	private void UpdateStats(float dt)
	{
		if (mStats == null)
			return;
		let shown = (mServices.Overlays != null) && mServices.Overlays.Settings.ShowFps;
		if (!shown)
		{
			mStats.Displayed = false;
			mStatsSeconds = 0.0;
			mStatsFrames = 0;
			mStatsText.Clear();
			return;
		}
		// Sampled over half a second, so it can be read.
		mStatsSeconds += (double)dt;
		mStatsFrames++;
		if ((mStatsSeconds >= 0.5) || mStatsText.IsEmpty)
		{
			mStatsText.Clear();
			FrameRateOverlay.Text(mStatsSeconds, mStatsFrames, mStatsText);
			mStatsSeconds = 0.0;
			mStatsFrames = 0;
			mStats.Text = mStatsText;
		}
		mStats.Displayed = true;
	}

	private void UpdateStatus()
	{
		if (mStatus == null)
			return;
		let active = (mServices.Tools != null) ? mServices.Tools.ActiveTool : null;
		StringView[4] parts = default;
		StringView icon = default;
		let snapText = scope String();
		let selectionText = scope String();
		let gizmos = (mServices.Gizmos != null) ? mServices.Gizmos() : null;
		if ((active != null) && (active == mServices.SelectTool) && (gizmos != null))
		{
			// The select tool in parts: what a drag does, in which space, by which step, to what.
			if (!gizmos.HandlesShown)
			{
				icon = "Editor/Icons/select.svg";
				parts[0] = "Select";
			}
			else
			{
				switch (gizmos.Mode)
				{
				case .Translate:
					icon = "Editor/Icons/move.svg";
					parts[0] = "Move";
				case .Rotate:
					icon = "Editor/Icons/rotate.svg";
					parts[0] = "Rotate";
				case .Scale:
					icon = "Editor/Icons/scale.svg";
					parts[0] = "Scale";
				}
				// Scale is always in the selection's own space.
				parts[1] = ((gizmos.Mode == .Scale) || (gizmos.Space == .Local)) ? "Local" : "World";
				if (gizmos.SnapMode)
				{
					let gizmo = gizmos.Gizmo;
					switch (gizmos.Mode)
					{
					case .Translate: snapText.AppendF("Snap {} m", StepText(gizmo.TranslateSnap, .. scope String()));
					case .Rotate: snapText.AppendF("Snap {}°", StepText(gizmo.RotateSnapDegrees, .. scope String()));
					case .Scale: snapText.AppendF("Snap {}", StepText(gizmo.ScaleSnap, .. scope String()));
					}
					parts[2] = snapText;
				}
			}
			if ((mServices.Edit != null) && !mServices.Edit.EntitySelection.IsEmpty)
			{
				let selection = mServices.Edit.EntitySelection;
				let e = mServices.Edit.Resolve(selection.Primary);
				if (e.IsAssigned)
				{
					let name = mServices.Edit.Scene.GetEntityName(e);
					if (selection.Count > 1)
						selectionText.AppendF("{} +{}", name, selection.Count - 1);
					else
						selectionText.Append(name);
					parts[3] = selectionText;
				}
			}
		}
		else if (active != null)
			parts[0] = active.StatusText; // a tool's own words, until each says it in parts (part 3)
		if (mStatusIcon != null)
		{
			mStatusIcon.Displayed = !icon.IsEmpty;
			if (!icon.IsEmpty && (mStatusIcon.Source != icon))
				mStatusIcon.Source = icon;
		}
		for (int i < 4)
		{
			if (let label = mStatusParts[i])
			{
				if (label.Text != parts[i])
					label.Text = parts[i];
				label.Displayed = !parts[i].IsEmpty;
			}
		}
		mStatus.Displayed = !parts[0].IsEmpty;
	}

	private void UpdateZoom(float dt, uint32 viewHeight)
	{
		mZoom.Advance(dt);
		let opacity = mZoom.Opacity;
		if (mZoomBox == null)
			return;
		mZoomBox.Displayed = opacity > 0.0f;
		if ((opacity <= 0.0f) || (mServices.Camera == null) || (mServices.Overlays == null))
			return;
		mZoomBox.Alpha = opacity;
		let camera = mServices.Camera;
		let bar = ZoomReadout.ScaleBarAt(camera.FocusDistance, camera.FovY, (float)Math.Max(viewHeight, 1));
		if (mZoomFocus != null)
		{
			let text = ZoomReadout.FormatMetres(camera.FocusDistance, .. scope String());
			text.Append(" to focus");
			mZoomFocus.Text = text;
		}
		if (mZoomCell != null)
		{
			let text = scope String("Grid cell ");
			ZoomReadout.FormatMetres(mServices.Overlays.CurrentGridSpacing(camera).Spacing, text);
			mZoomCell.Text = text;
		}
		if (mZoomLength != null)
			mZoomLength.Text = ZoomReadout.FormatMetres(bar.Metres, .. scope String());
		if (mZoomBar != null)
			mZoomBar.SetLength(bar.Pixels);
	}

	// A texture's pass: what its name says before its first '.' ("ssgi.filtered": ssgi).
	private static void PassOf(StringView name, String outPass)
	{
		let dot = name.IndexOf('.');
		outPass.Append((dot >= 0) ? name.Substring(0, dot) : "other");
	}

	// A step as the snap menu writes it: to two decimals, none it does not need ("0.25", "1").
	private static void StepText(float value, String outText)
	{
		let hundredths = (int64)(value * 100.0f + 0.5f);
		let whole = hundredths / 100;
		let part = hundredths % 100;
		if (part == 0)
			outText.AppendF("{}", whole);
		else if (part % 10 == 0)
			outText.AppendF("{}.{}", whole, part / 10);
		else
			outText.AppendF("{}.{}{}", whole, part / 10, part % 10);
	}

	private static StringView NameOfTerm(ViewDebugSemantic semantic)
	{
		if (semantic == .Albedo)
			return "Unlit";
		for (let term in sTerms)
		{
			if (term.Semantic == semantic)
				return term.Label;
		}
		return "Lit";
	}
}
