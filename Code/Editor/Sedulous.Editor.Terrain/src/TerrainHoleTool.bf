using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The terrain hole brush: Cut removes the surface under the disc and Fill restores it.
///
/// A modal tool beside sculpt and splat. It ray picks the terrain under the cursor into
/// heightfield local space, cuts or fills the samples inside a HARD EDGED disc, and records
/// one region delta undo command per stroke over the hole plane. On save the registered
/// closure writes the grid back to its source asset.
///
/// The ray query passes THROUGH a cut, so the brush cannot pick inside a hole: to fill one,
/// the author picks from its rim outward and the disc covers the cut.
///
/// The scene, commands and edit sink are BORROWED from the host; a null sink means no
/// persistence, which is what a test wants.
class TerrainHoleTool : IViewportTool
{
	public const float cMinRadius = 0.5f;
	public const float cMaxRadius = 128.0f;

	private Scene mScene;
	private EditorCommandStack mCommands;
	private IAssetEditSink mAssetEdits;

	private HoleMode mMode = .Cut;
	/// World units.
	private float mRadius = 6.0f;

	private bool mHasHover = false;
	private Float3 mHoverWorld = .Zero;
	private Float3 mHoverNormal = .(0.0f, 1.0f, 0.0f);

	private bool mStroking = false;
	private Ref<Heightfield> mStrokeGrid = default;
	/// The WHOLE plane at the press, which the region is sliced out of at the release.
	private List<uint8> mBefore = new .() ~ delete _;
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

	public StringView Id => "terrain.hole";
	public StringView DisplayName => "Cut Holes";
	public StringView StatusText => mStatus;

	public StringView UnavailableReason =>
		"Cut Holes needs a terrain with a heightfield in the scene.";

	public bool IsAvailable => SculptPick.AnyTerrain(mScene);

	public HoleMode Mode => mMode;
	public void SetMode(HoleMode mode)
	{
		mMode = mode;
		UpdateStatus();
	}

	public float Radius => mRadius;
	public void SetRadius(float radius)
	{
		mRadius = Math.Clamp(radius, cMinRadius, cMaxRadius);
		UpdateStatus();
		if (OnRadiusChanged != null)
			OnRadiusChanged(mRadius);
	}

	public bool IsStroking => mStroking;
	public bool HasHover => mHasHover;

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
			if (kb.IsKeyPressed(.Num1)) SetMode(.Cut);
			if (kb.IsKeyPressed(.Num2)) SetMode(.Fill);
		}
		if (input.PointerOver && (input.WheelDelta != 0.0f))
			SetRadius(mRadius * (1.0f + 0.12f * input.WheelDelta));

		let pick = SculptPick.Resolve(mScene, input);
		if (pick.Valid)
		{
			mHasHover = true;
			mHoverWorld = pick.WorldHit;
			mHoverNormal = pick.WorldNormal;
		}

		var consumed = mStroking;
		// Simulate: the collider is shared with the running world, so no edits.
		if (!input.EditingLocked)
		{
			if (!mStroking && pick.Valid && input.PointerOver && input.LeftPressed)
			{
				BeginStroke(pick);
				consumed = true;
			}
			else if (mStroking && input.LeftDown && pick.Valid
				&& (pick.Grid.Get === mStrokeGrid.Get))
			{
				ApplyDab(pick);
				consumed = true;
			}
			if (mStroking && (input.LeftReleased || !input.PointerValid))
				EndStroke();
		}
		else if (mStroking)
		{
			EndStroke();
		}

		UpdateStatus();
		return consumed;
	}

	public void Draw(DebugDraw drawList)
	{
		if (!mHasHover)
			return;

		// A HARD edged disc, so one ring and no inner falloff circle: magenta to cut and
		// green to fill.
		let ring = (mMode == .Cut)
			? Color(1.0f, 0.25f, 0.9f, 1.0f)
			: Color(0.35f, 1.0f, 0.45f, 1.0f);
		drawList.DrawCircleNormal(mHoverWorld, mRadius, mHoverNormal, ring, 40, true);
	}

	private void BeginStroke(in SculptPick pick)
	{
		let grid = pick.Grid.Get;
		if (grid == null)
			return;

		mStroking = true;
		mStrokeGrid = pick.Grid;
		mBefore.Clear();
		mBefore.AddRange(grid.Holes);
		mRegion = .();
		ApplyDab(pick);
	}

	private void ApplyDab(in SculptPick pick)
	{
		let grid = mStrokeGrid.Get;
		if (grid == null)
			return;

		let region = (mMode == .Cut)
			? HeightfieldHoles.Cut(grid, pick.LocalX, pick.LocalZ, mRadius)
			: HeightfieldHoles.Fill(grid, pick.LocalX, pick.LocalZ, mRadius);
		if (!region.IsEmpty)
		{
			mRegion.Add(region.MinX, region.MinZ);
			mRegion.Add(region.MaxX, region.MaxZ);
		}
	}

	private void EndStroke()
	{
		let grid = mStrokeGrid.Get;
		if (mStroking && (grid != null) && !mRegion.IsEmpty)
		{
			let before = scope List<uint8>();
			let after = scope List<uint8>();
			HoleStrokeCommand.SliceRegion(mBefore, grid.Size, mRegion, before);
			HoleStrokeCommand.SliceRegion(grid.Holes, grid.Size, mRegion, after);

			var changed = false;
			for (int i < before.Count)
			{
				if (before[i] != after[i])
				{
					changed = true;
					break;
				}
			}

			// A fill over solid ground, or a cut over a cut, is no command.
			if (changed)
			{
				mCommands.Execute(new HoleStrokeCommand(mStrokeGrid, mRegion, before, after));
				if ((mAssetEdits != null) && mStrokeGrid.Id.IsSet)
				{
					mAssetEdits.RegisterAssetEdit(mStrokeGrid.Id,
						TerrainPersist.ForHeightfield(grid, mStrokeGrid.Id));
				}
			}
		}

		mStroking = false;
		mStrokeGrid = default;
		mBefore.Clear();
		mRegion = .();
	}

	private void UpdateStatus()
	{
		let radius = (int32)(mRadius + 0.5f);
		let mode = (mMode == .Cut) ? "CUT" : "FILL";
		mStatus.Set(scope $"Cut Holes [{mode}]  radius {radius}  (1 cut, 2 fill, wheel size)");
	}
}
