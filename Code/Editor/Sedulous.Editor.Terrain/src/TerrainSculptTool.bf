using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The terrain sculpt brush: raise, lower, smooth or flatten the heightfield under the
/// cursor. A press-drag-release is one stroke, one undo step over the touched region, and
/// one registered asset edit persisting the grid back to its source. Keys 1 to 4 pick the
/// mode, Shift and the wheel size the brush, Ctrl+click picks the flatten target.
///
/// The scene, commands and edit sink are BORROWED from the host; a null sink means no
/// persistence, which is what a test wants.
class TerrainSculptTool : IViewportTool
{
	public const float cMinRadius = 0.5f;
	public const float cMaxRadius = 128.0f;
	public const float cMaxStrength = 50.0f;

	private Scene mScene;
	private EditorCommandStack mCommands;
	private IAssetEditSink mAssetEdits;

	private SculptMode mMode = .Raise;
	/// World units.
	private float mRadius = 6.0f;
	/// World Y units per second at the brush centre.
	private float mStrength = 8.0f;
	private float mFlattenTarget = 0.0f;
	private bool mHasFlattenTarget = false;

	private bool mHasHover = false;
	private Float3 mHoverWorld = .Zero;
	private Float3 mHoverNormal = .(0.0f, 1.0f, 0.0f);

	private bool mStroking = false;
	private Ref<Heightfield> mStrokeGrid = default;
	private List<uint16> mBefore = new .() ~ delete _;
	private HeightfieldRegion mRegion = .();
	private String mStatus = new .() ~ delete _;

	/// The panel's radius readout follows wheel sizing through this. Owned.
	public delegate void(float radius) OnRadiusChanged = null ~ delete _;

	public this(Scene scene, EditorCommandStack commands, IAssetEditSink assetEdits)
	{
		mScene = scene;
		mCommands = commands;
		mAssetEdits = assetEdits;
		UpdateStatus();
	}

	public StringView Id => "terrain.sculpt";
	public StringView DisplayName => "Sculpt Terrain";
	public StringView Category => "Terrain";
	public StringView StatusText => mStatus;

	public SculptMode Mode => mMode;
	public void SetMode(SculptMode mode) { mMode = mode; }

	public float Radius => mRadius;
	public void SetRadius(float radius)
	{
		mRadius = Math.Clamp(radius, cMinRadius, cMaxRadius);
		if (OnRadiusChanged != null)
			OnRadiusChanged(mRadius);
	}

	public float Strength => mStrength;
	public void SetStrength(float strength) { mStrength = Math.Clamp(strength, 0.0f, cMaxStrength); }

	public bool IsStroking => mStroking;
	public bool HasHover => mHasHover;

	/// Any terrain in the scene with a resolved, non empty heightfield.
	public StringView UnavailableReason =>
		"Sculpt needs a terrain with a heightfield in the scene.";

	public bool IsAvailable
	{
		get
		{
			let manager = (mScene != null) ? mScene.GetSystem<TerrainComponentManager>() : null;
			if (manager == null)
				return false;
			var any = false;
			manager.ForEach(scope [&] (component, owner) =>
				{
					let res = component.Terrain.Get;
					if (res == null)
						return;
					let grid = res.Heightfield.Get;
					if ((grid == null) || grid.IsEmpty)
						return;
					any = true;
				});
			return any;
		}
	}

	public void OnActivate() {}

	public void OnDeactivate()
	{
		if (mStroking)
			EndStroke(); // never leave a half open stroke on a tool switch
		mHasHover = false;
		DeleteAndNullify!(OnRadiusChanged);
	}

	public bool Update(in ViewportToolInput input)
	{
		mHasHover = false;
		let kb = input.Keyboard;
		if ((kb != null) && input.PointerValid)
		{
			if (kb.IsKeyPressed(.Num1)) mMode = .Raise;
			if (kb.IsKeyPressed(.Num2)) mMode = .Lower;
			if (kb.IsKeyPressed(.Num3)) mMode = .Smooth;
			if (kb.IsKeyPressed(.Num4)) mMode = .Flatten;
		}
		// SHIFT and the wheel resizes the brush; the bare wheel stays the camera's dolly.
		if (input.PointerOver && input.Shift && (input.WheelDelta != 0.0f))
			SetRadius(mRadius * (1.0f + 0.12f * input.WheelDelta));

		let pick = SculptPick.Resolve(mScene, input);
		if (pick.Valid)
		{
			mHasHover = true;
			mHoverWorld = pick.WorldHit;
			mHoverNormal = pick.WorldNormal;
		}

		var consumed = mStroking;
		if (pick.Valid && input.PointerOver && input.LeftPressed && input.Ctrl)
		{
			mFlattenTarget = pick.LocalY;
			mHasFlattenTarget = true;
			mMode = .Flatten;
			UpdateStatus();
			return true;
		}

		if (!input.EditingLocked) // Simulate: the collider is shared, so no edits
		{
			if (!mStroking && pick.Valid && input.PointerOver && input.LeftPressed && !input.Ctrl)
			{
				BeginStroke(pick);
				consumed = true;
			}
			else if (mStroking && input.LeftDown && pick.Valid && (pick.Grid.Get === mStrokeGrid.Get))
			{
				ApplyDab(pick, input.DeltaSeconds);
				consumed = true;
			}
			if (mStroking && (input.LeftReleased || !input.PointerValid))
				EndStroke();
		}
		else if (mStroking)
			EndStroke(); // Simulate started mid stroke: commit what was painted, then stop

		UpdateStatus();
		return consumed;
	}

	public void Draw(DebugDraw drawList)
	{
		if (!mHasHover)
			return;
		let ring = (mMode == .Lower) ? Color(1.0f, 0.55f, 0.2f, 1.0f) : Color(0.3f, 0.9f, 1.0f, 1.0f);
		drawList.DrawCircleNormal(mHoverWorld, mRadius, mHoverNormal, ring, 40, true);
		drawList.DrawCircleNormal(mHoverWorld, mRadius * 0.5f, mHoverNormal, .(ring.R, ring.G, ring.B, 0.5f), 32, true);
	}

	/// The nearest terrain the ray hits, in that terrain's local space.
	private void BeginStroke(in SculptPick pick)
	{
		mStroking = true;
		mStrokeGrid = pick.Grid;
		let grid = mStrokeGrid.Get;
		mBefore.Clear();
		mBefore.AddRange(grid.Samples);
		mRegion = .();
		ApplyDab(pick, 0.0f); // an instant click still deposits one dab
	}

	private void ApplyDab(in SculptPick pick, float deltaSeconds)
	{
		let grid = mStrokeGrid.Get;
		if (grid == null)
			return;
		let step = mStrength * ((deltaSeconds > 0.0f) ? deltaSeconds : (1.0f / 60.0f));
		var r = HeightfieldRegion();
		switch (mMode)
		{
		case .Raise:
			r = HeightfieldSculpt.Raise(grid, pick.LocalX, pick.LocalZ, mRadius, step);
		case .Lower:
			r = HeightfieldSculpt.Raise(grid, pick.LocalX, pick.LocalZ, mRadius, -step);
		case .Smooth:
			r = HeightfieldSculpt.Smooth(grid, pick.LocalX, pick.LocalZ, mRadius, Math.Clamp(step * 0.5f, 0.0f, 1.0f));
		case .Flatten:
			let target = mHasFlattenTarget ? mFlattenTarget : pick.LocalY;
			r = HeightfieldSculpt.Flatten(grid, pick.LocalX, pick.LocalZ, mRadius, Math.Clamp(step * 0.5f, 0.0f, 1.0f), target);
		}
		if (!r.IsEmpty)
		{
			mRegion.Add(r.MinX, r.MinZ);
			mRegion.Add(r.MaxX, r.MaxZ);
		}
	}

	private void EndStroke()
	{
		let grid = mStrokeGrid.Get;
		if (mStroking && (grid != null) && !mRegion.IsEmpty)
		{
			let before = scope List<uint16>();
			let after = scope List<uint16>();
			SculptStrokeCommand.SliceRegion(mBefore, grid.Size, mRegion, before);
			SculptStrokeCommand.SliceRegion(grid.Samples, grid.Size, mRegion, after);
			mCommands.Execute(new SculptStrokeCommand(mStrokeGrid, mRegion, before, after));
			if ((mAssetEdits != null) && mStrokeGrid.Id.IsSet)
				mAssetEdits.RegisterAssetEdit(mStrokeGrid.Id, TerrainPersist.ForHeightfield(grid, mStrokeGrid.Id));
		}
		mStroking = false;
		mStrokeGrid = default;
		mBefore.Clear();
		mRegion = .();
	}

	private void UpdateStatus()
	{
		StringView modeText = "Raise";
		switch (mMode)
		{
		case .Raise: modeText = "Raise";
		case .Lower: modeText = "Lower";
		case .Smooth: modeText = "Smooth";
		case .Flatten: modeText = "Flatten";
		}
		mStatus.Set(scope $"Sculpt [{modeText}]  radius {(int32)(mRadius + 0.5f)}  strength {(int32)(mStrength + 0.5f)}  (1-4 mode, Shift+wheel size, Ctrl+click = flatten target)");
	}
}
