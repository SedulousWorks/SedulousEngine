using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Vegetation.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Vegetation;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The vegetation brush: paints density into one plane of the terrain's mask, erases it
/// back, or smooths a painted edge. Stamps are spaced along the drag by a fraction of the
/// radius, so holding still adds nothing unless airbrush mode is on, which stamps on a time
/// cadence instead. A stroke is one undo step over the plane and one registered asset edit.
/// Keys 1 to 9 pick a plane, 0 the eraser, minus smooth, and the wheel sizes the brush.
///
/// Every stamp tells the vegetation manager the footprint it touched, so only the chunks
/// under the brush regrow rather than the whole terrain.
///
/// The scene, commands and edit sink are BORROWED from the host; a null sink means no
/// persistence.
class VegetationPaintTool : IViewportTool
{
	public const float cMinRadius = 0.5f;
	public const float cMaxRadius = 128.0f;
	/// Teleport guard: alt-tab warps and huge drags.
	private const int32 cMaxStampsPerFrame = 1024;
	/// Seconds per time cadence stamp, twenty a second.
	private const float cAirbrushPeriod = 0.05f;

	private Scene mScene;
	private EditorCommandStack mCommands;
	private IAssetEditSink mAssetEdits;

	private uint32 mPlane = 0;
	private bool mErase = false;
	private bool mSmooth = false;
	private bool mAirbrush = false;
	/// World units.
	private float mRadius = 6.0f;
	/// Density per stamp, nought to one.
	private float mStrength = 1.0f;
	/// Stamp spacing as a fraction of the radius.
	private float mSpacing = 0.25f;

	private bool mHasHover = false;
	private Float3 mHoverWorld = .Zero;
	private Float3 mHoverNormal = .(0.0f, 1.0f, 0.0f);

	private bool mStroking = false;
	private Ref<VegetationMask> mStrokeMask = default;
	private EntityHandle mStrokeOwner = .();
	private int32 mStrokeGridSize = 0;
	private List<uint8> mBefore = new .() ~ delete _;
	private MaskRegion mRegion = .();
	private float mLastStampU = 0.0f;
	private float mLastStampV = 0.0f;
	private float mAirbrushClock = 0.0f;
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

	public StringView Id => "vegetation.paint";
	public StringView DisplayName => "Paint Vegetation";
	public StringView StatusText => mStatus;

	public uint32 Plane => mPlane;
	/// Picking a plane leaves eraser and smooth mode.
	public void SetPlane(uint32 plane)
	{
		mPlane = Math.Min(plane, VegetationMask.cMaxPlanes - 1);
		mErase = false;
		mSmooth = false;
		UpdateStatus();
	}

	public bool IsEraser => mErase;
	public void SetEraser(bool on)
	{
		mErase = on;
		if (on)
			mSmooth = false;
		UpdateStatus();
	}

	public bool IsSmooth => mSmooth;
	public void SetSmooth(bool on)
	{
		mSmooth = on;
		if (on)
			mErase = false;
		UpdateStatus();
	}

	public bool IsAirbrush => mAirbrush;
	public void SetAirbrush(bool on) { mAirbrush = on; }

	public float Radius => mRadius;
	public void SetRadius(float radius)
	{
		mRadius = Math.Clamp(radius, cMinRadius, cMaxRadius);
		UpdateStatus();
		if (OnRadiusChanged != null)
			OnRadiusChanged(mRadius);
	}

	public float Strength => mStrength;
	public void SetStrength(float strength) { mStrength = Math.Clamp(strength, 0.0f, 1.0f); }

	public float Spacing => mSpacing;
	public void SetSpacing(float spacing) { mSpacing = Math.Clamp(spacing, 0.05f, 1.0f); }

	public bool IsStroking => mStroking;
	public bool HasHover => mHasHover;

	/// Any terrain in the scene whose vegetation component resolves a non empty mask, and
	/// whose heightfield is what the ray hits.
	public bool IsAvailable => VegetationPick.AnyFootprint(mScene, true);

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
			if (kb.IsKeyPressed(.Num1)) SetPlane(0);
			if (kb.IsKeyPressed(.Num2)) SetPlane(1);
			if (kb.IsKeyPressed(.Num3)) SetPlane(2);
			if (kb.IsKeyPressed(.Num4)) SetPlane(3);
			if (kb.IsKeyPressed(.Num5)) SetPlane(4);
			if (kb.IsKeyPressed(.Num6)) SetPlane(5);
			if (kb.IsKeyPressed(.Num7)) SetPlane(6);
			if (kb.IsKeyPressed(.Num8)) SetPlane(7);
			if (kb.IsKeyPressed(.Num9)) SetPlane(8);
			if (kb.IsKeyPressed(.Num0)) SetEraser(true);
			if (kb.IsKeyPressed(.Minus)) SetSmooth(true);
		}
		if (input.PointerOver && (input.WheelDelta != 0.0f))
			SetRadius(mRadius * (1.0f + 0.12f * input.WheelDelta));

		let pick = VegetationPick.Resolve(mScene, input.Ray.Origin, input.Ray.Direction, true);
		if (pick.Valid)
		{
			mHasHover = true;
			mHoverWorld = pick.WorldHit;
			mHoverNormal = pick.WorldNormal;
		}

		var consumed = mStroking;
		// Simulate: the mask feeds the live scatter, so no edits.
		if (!input.EditingLocked)
		{
			if (!mStroking && pick.Valid && input.PointerOver && input.LeftPressed)
			{
				BeginStroke(pick);
				consumed = true;
			}
			else if (mStroking && input.LeftDown && pick.Valid
				&& (pick.Mask.Get === mStrokeMask.Get))
			{
				AdvanceStroke(pick, input.DeltaSeconds);
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

		var ring = Color(0.45f, 0.85f, 0.35f, 1.0f); // a growing green
		if (mSmooth)
			ring = .(0.55f, 0.75f, 0.95f, 1.0f);
		else if (mErase)
			ring = .(0.95f, 0.6f, 0.35f, 1.0f);
		drawList.DrawCircleNormal(mHoverWorld, mRadius, mHoverNormal, ring, 40, true);
		drawList.DrawCircleNormal(mHoverWorld, mRadius * 0.5f, mHoverNormal,
			.(ring.R, ring.G, ring.B, 0.5f), 32, true);
	}

	private void BeginStroke(in VegetationPick pick)
	{
		let mask = pick.Mask.Get;
		let plane = mask.Plane(mPlane);
		if (plane.IsEmpty)
			return; // the plane this brush paints is not on this mask

		mStroking = true;
		mStrokeMask = pick.Mask;
		mStrokeOwner = pick.Owner;
		mStrokeGridSize = pick.GridSize;
		mBefore.Clear();
		mBefore.AddRange(plane);
		mRegion = .();
		mAirbrushClock = 0.0f;
		ApplyStamp(pick.UvX, pick.UvY, pick, mStrength);
		mLastStampU = pick.UvX;
		mLastStampV = pick.UvY;
	}

	/// Walks stamps from the last one toward the pointer at the spacing, the remainder
	/// carrying to the next frame; airbrush adds time cadence stamps at the pointer.
	private void AdvanceStroke(in VegetationPick pick, float deltaSeconds)
	{
		if (mStrokeMask.Get == null)
			return;

		let spacing = Math.Max(mRadius * mSpacing, 1e-4f);
		for (int32 i < cMaxStampsPerFrame)
		{
			let dxWorld = (pick.UvX - mLastStampU) * pick.WorldSizeX;
			let dyWorld = (pick.UvY - mLastStampV) * pick.WorldSizeY;
			let distance = Math.Sqrt(dxWorld * dxWorld + dyWorld * dyWorld);
			if (distance < spacing)
				break; // no partial stamps

			let f = spacing / distance;
			mLastStampU += (pick.UvX - mLastStampU) * f;
			mLastStampV += (pick.UvY - mLastStampV) * f;
			ApplyStamp(mLastStampU, mLastStampV, pick, mStrength);
		}

		if (mAirbrush)
		{
			mAirbrushClock += Math.Max(deltaSeconds, 0.0f);
			for (int32 i = 0; (mAirbrushClock >= cAirbrushPeriod) && (i < cMaxStampsPerFrame); i++)
			{
				mAirbrushClock -= cAirbrushPeriod;
				ApplyStamp(pick.UvX, pick.UvY, pick, mStrength * cAirbrushPeriod);
			}
		}
	}

	private void ApplyStamp(float uvX, float uvY, in VegetationPick pick, float amount)
	{
		let mask = mStrokeMask.Get;
		if (mask == null)
			return;

		let uvRadiusX = mRadius / pick.WorldSizeX;
		let uvRadiusY = mRadius / pick.WorldSizeY;
		let t = Math.Clamp(amount, 0.0f, 1.0f);
		let core = 0.5f * t;

		MaskRegion r;
		if (mSmooth)
			r = MaskBrush.Smooth(mask, mPlane, uvX, uvY, uvRadiusX, uvRadiusY, t, core);
		else if (mErase)
			r = MaskBrush.Erase(mask, mPlane, uvX, uvY, uvRadiusX, uvRadiusY, t, core);
		else
			r = MaskBrush.Paint(mask, mPlane, uvX, uvY, uvRadiusX, uvRadiusY, t, core);

		if (r.IsEmpty)
			return;

		mRegion.Add(r.MinX, r.MinY);
		mRegion.Add(r.MaxX, r.MaxY);
		// Only the chunks under THIS stamp regrow, rather than the whole terrain.
		NotifyRegion(r);
	}

	/// Maps a mask texel rect onto the terrain's footprint and hands it to the manager.
	private void NotifyRegion(MaskRegion region)
	{
		let manager = (mScene != null) ? mScene.GetSystem<TerrainVegetationComponentManager>() : null;
		let mask = mStrokeMask.Get;
		if ((manager == null) || (mask == null) || mask.IsEmpty || region.IsEmpty
			|| (mStrokeGridSize <= 1))
			return;

		let w = (float)mask.Width;
		let h = (float)mask.Height;
		manager.InvalidateFootprint((float)region.MinX / w, (float)region.MinY / h,
			(float)(region.MaxX + 1) / w, (float)(region.MaxY + 1) / h, mStrokeGridSize);
	}

	private void EndStroke()
	{
		let mask = mStrokeMask.Get;
		if (mStroking && (mask != null) && !mRegion.IsEmpty)
		{
			let plane = mask.Plane(mPlane);
			if (!plane.IsEmpty)
			{
				let before = scope List<uint8>();
				let after = scope List<uint8>();
				VegetationStrokeCommand.SliceRegion(mBefore, mask.Width, mRegion, before);
				VegetationStrokeCommand.SliceRegion(plane, mask.Width, mRegion, after);

				// Undo and redo re-notify, so the chunks regrow both ways.
				let scene = mScene;
				let gridSize = mStrokeGridSize;
				let maskRef = mStrokeMask;
				mCommands.Execute(new VegetationStrokeCommand(mStrokeMask, mPlane, mRegion,
					before, after,
					new [=scene, =gridSize, =maskRef](region) =>
					{
						let manager = (scene != null)
							? scene.GetSystem<TerrainVegetationComponentManager>() : null;
						let live = maskRef.Get;
						if ((manager == null) || (live == null) || live.IsEmpty || (gridSize <= 1))
							return;
						let w = (float)live.Width;
						let h = (float)live.Height;
						manager.InvalidateFootprint((float)region.MinX / w, (float)region.MinY / h,
							(float)(region.MaxX + 1) / w, (float)(region.MaxY + 1) / h, gridSize);
					}));

				if ((mAssetEdits != null) && mStrokeMask.Id.IsSet)
					mAssetEdits.RegisterAssetEdit(mStrokeMask.Id,
						VegetationPersist.ForMask(mask, mStrokeMask.Id));
			}
		}

		mStroking = false;
		mStrokeMask = default;
		mStrokeOwner = .();
		mStrokeGridSize = 0;
		mBefore.Clear();
		mRegion = .();
	}

	private void UpdateStatus()
	{
		let radius = (int32)(mRadius + 0.5f);
		let keys = "(1-9 plane, 0 eraser, - smooth, wheel size)";
		if (mSmooth)
			mStatus.Set(scope $"Paint Vegetation [SMOOTH]  radius {radius}  {keys}");
		else if (mErase)
			mStatus.Set(scope $"Paint Vegetation [ERASER]  radius {radius}  {keys}");
		else
			mStatus.Set(scope $"Paint Vegetation [plane {mPlane}]  radius {radius}  {keys}");
	}
}
