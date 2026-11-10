using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// The scene page's bar: Save, Undo and Redo;
// Select, Move, Rotate and Scale as one choice; the space, its icon the space it is in; Snap,
// every drag snapping while it is on, with its increments in its menu (they had no UI: Ctrl
// snapped by fixed steps); Vertex Snap; Simulate, Pause and Stop, the state named beside them
// while it runs (Simulate is named so, Play is the Game tab's); Frame; the
// property animation panel shown or not (the old bar's Animation). Each button is an action over the page
// (PageActionBar), so its tooltip says its keys and it is disabled where the action is (the
// transform choice while the camera owns the keys). The view's own controls are the HUD's chips,
// not the bar's.
class SceneBar
{
	/// An increment the snap menu offers; 0 for a move: the grid's cell.
	public struct Increment
	{
		public float Value;
		public String Label;

		public this(float value, String label)
		{
			Value = value;
			Label = label;
		}
	}

	public static Increment[6] sMoveIncrements = .(.(0.1f, "0.1 m"), .(0.25f, "0.25 m"), .(0.5f, "0.5 m"), .(1.0f, "1 m"), .(2.0f, "2 m"), .(0.0f, "The grid's cell"));
	public static Increment[4] sRotateIncrements = .(.(5.0f, "5°"), .(15.0f, "15°"), .(45.0f, "45°"), .(90.0f, "90°"));
	public static Increment[3] sScaleIncrements = .(.(0.1f, "0.1"), .(0.25f, "0.25"), .(0.5f, "0.5"));

	public enum SnapKind : uint8
	{
		Move,
		Rotate,
		Scale,
	}

	private PageActionBar mBar ~ delete _;
	/// Borrowed: it outlives its bar.
	private EditorPage mPage;
	/// The page's: the label naming Simulate's state; null: none.
	private Sedulous.GUI.Label mState;
	private bool mPaused = false;
	private bool mStateShown = false;
	private delegate GizmoController() mGizmos ~ delete _;
	// The page's, which outlives its bar.
	private ButtonBase mSpace = null;
	private bool mWorld = true;
	private bool mSpaceShown = false;
	// The menu's, which the button keeps.
	private List<MenuItem> mMoveItems = new .() ~ delete _;
	private List<MenuItem> mRotateItems = new .() ~ delete _;
	private List<MenuItem> mScaleItems = new .() ~ delete _;

	/// The bar's buttons, by their markup ids (`scene-save` ... `scene-frame`), found by `find`;
	/// `state` the label naming Simulate's state (null: none); `gizmos` (taken) the page's
	/// controller, asked each time (the tool may come later). `actions`, `page` and `state` are
	/// borrowed and outlive it.
	public this(EditorActionRegistry actions, EditorPage page, delegate ButtonBase(StringView id) find, Sedulous.GUI.Label state,
		delegate GizmoController() gizmos)
	{
		mBar = new .(actions, page);
		mPage = page;
		mState = state;
		mGizmos = gizmos;
		mBar.Bind(find("scene-save"), "file.save");
		mBar.Bind(find("scene-undo"), "edit.undo");
		mBar.Bind(find("scene-redo"), "edit.redo");
		mBar.Bind(find("scene-discard"), "page.discardChanges");
		mBar.Bind(find("scene-select"), SceneActionIds.GizmoSelect);
		mBar.Bind(find("scene-move"), SceneActionIds.GizmoTranslate);
		mBar.Bind(find("scene-rotate"), SceneActionIds.GizmoRotate);
		mBar.Bind(find("scene-scale"), SceneActionIds.GizmoScale);
		mSpace = find("scene-space");
		mBar.Bind(mSpace, SceneActionIds.GizmoWorldSpace);
		let snap = find("scene-snap");
		mBar.Bind(snap, SceneActionIds.GizmoSnap);
		mBar.Bind(find("scene-vertex-snap"), SceneActionIds.GizmoVertexSnap);
		mBar.Bind(find("scene-simulate"), SceneActionIds.SimulateStart);
		mBar.Bind(find("scene-pause"), SceneActionIds.SimulatePause);
		mBar.Bind(find("scene-stop"), SceneActionIds.SimulateStop);
		mBar.Bind(find("scene-frame"), SceneActionIds.FrameSelection);
		mBar.Bind(find("scene-animation-panel"), SceneActionIds.AnimationPanel);
		if (let menuButton = snap as ToolMenuButton)
			BuildSnapMenu(menuButton.Menu);
		SyncState(); // hidden until it runs
	}

	/// How many buttons are bound to actions.
	public int Bound => mBar.Count;

	/// What the state label says ("Simulating", "Paused"); empty while it shows nothing.
	public StringView State => ((mState != null) && mState.Visible) ? mState.Text : default;

	/// Once a frame: each button as its action is now over the page; the space's icon and the
	/// increments' checks as the gizmo has them.
	public void Sync()
	{
		mBar.Sync();
		SyncState();
		let gizmos = (mGizmos != null) ? mGizmos() : null;
		if (gizmos == null)
			return;
		let world = gizmos.Space == .World;
		if ((mSpace != null) && (!mSpaceShown || (world != mWorld)))
		{
			mSpace.Icon = world ? "Editor/Icons/world.svg" : "Editor/Icons/local.svg";
			mWorld = world;
			mSpaceShown = true;
		}
		let gizmo = gizmos.Gizmo;
		Check(mMoveItems, sMoveIncrements, gizmos.MoveSnapsToGrid ? 0.0f : gizmo.TranslateSnap);
		Check(mRotateItems, sRotateIncrements, gizmo.RotateSnapDegrees);
		Check(mScaleItems, sScaleIncrements, gizmo.ScaleSnap);
	}

	// Simulate's state beside its buttons: shown while it runs, the edits locked meanwhile. Its place
	// is kept while it shows nothing, and its width is the sheet's whatever it says, so the buttons
	// centred beside it never move as it starts, pauses or stops.
	private void SyncState()
	{
		if (mState == null)
			return;
		let scene = mPage as ISceneEditorPage;
		let running = (scene != null) && scene.IsSimulating;
		let paused = running && scene.IsPaused;
		if (mState.Visible != running)
			mState.Visible = running;
		if (!running || (mStateShown && (paused == mPaused)))
			return;
		mState.Text = paused ? "Paused" : "Simulating";
		mState.RemoveClass(paused ? "playing" : "paused");
		mState.AddClass(paused ? "paused" : "playing");
		mState.Tooltip = "The scene runs here; edits wait until Stop, which puts it back as it was";
		mPaused = paused;
		mStateShown = true;
	}

	/// Picks the `index`th increment of `kind`, as its menu item does.
	public void PickIncrement(SnapKind kind, int index)
	{
		let gizmos = (mGizmos != null) ? mGizmos() : null;
		if (gizmos == null)
			return;
		let gizmo = gizmos.Gizmo;
		switch (kind)
		{
		case .Move:
			if ((index >= 0) && (index < sMoveIncrements.Count))
			{
				gizmos.MoveSnapsToGrid = sMoveIncrements[index].Value == 0.0f;
				if (sMoveIncrements[index].Value > 0.0f)
					gizmo.TranslateSnap = sMoveIncrements[index].Value;
			}
		case .Rotate:
			if ((index >= 0) && (index < sRotateIncrements.Count))
				gizmo.RotateSnapDegrees = sRotateIncrements[index].Value;
		case .Scale:
			if ((index >= 0) && (index < sScaleIncrements.Count))
				gizmo.ScaleSnap = sScaleIncrements[index].Value;
		}
		Sync();
	}

	private void BuildSnapMenu(Menu menu)
	{
		AddIncrements(menu.AddSubMenu("Move"), .Move, sMoveIncrements, mMoveItems);
		AddIncrements(menu.AddSubMenu("Rotate"), .Rotate, sRotateIncrements, mRotateItems);
		AddIncrements(menu.AddSubMenu("Scale"), .Scale, sScaleIncrements, mScaleItems);
	}

	private void AddIncrements(Menu menu, SnapKind kind, Span<Increment> increments, List<MenuItem> outItems)
	{
		for (int i < increments.Length)
		{
			let index = i;
			outItems.Add(menu.AddCheckItem(increments[i].Label, false, new [=this, =kind, =index] (on) => { PickIncrement(kind, index); }));
		}
	}

	// The item whose increment is `value` checked, the others not (a value no item has checks
	// none).
	private static void Check(List<MenuItem> items, Span<Increment> increments, float value)
	{
		for (int i < Math.Min(items.Count, increments.Length))
		{
			let on = increments[i].Value == value;
			if (items[i].Checked != on)
				items[i].SetCheckedSilently(on);
		}
	}
}
