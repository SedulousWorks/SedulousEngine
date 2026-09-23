using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The terrain splat brush: paints a palette layer into the top four weights under the
/// cursor, erases back to the base, or smooths a painted seam. Stamps are spaced along the
/// drag by a fraction of the radius, so holding still adds nothing unless airbrush mode
/// is on, which stamps on a time cadence instead. A stroke is one undo step over both
/// rasters and one registered asset edit. Keys 1 to 9 pick a layer, 0 the eraser, minus
/// smooth, the wheel sizes the brush.
///
/// The scene, commands and edit sink are BORROWED from the host; a null sink means no
/// persistence.
class TerrainSplatTool : IViewportTool
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

	private uint32 mPaletteIndex = 0;
	private bool mErase = false;
	private bool mSmooth = false;
	private bool mAirbrush = false;
	/// World units.
	private float mRadius = 6.0f;
	/// Coverage per stamp, zero to one.
	private float mStrength = 1.0f;
	/// Stamp spacing as a fraction of the radius.
	private float mSpacing = 0.25f;

	private bool mHasHover = false;
	private Float3 mHoverWorld = .Zero;
	private Float3 mHoverNormal = .(0.0f, 1.0f, 0.0f);

	private bool mStroking = false;
	private Ref<SplatWeights> mStrokeWeights = default;
	private List<uint8> mBeforeWeights = new .() ~ delete _;
	private List<uint8> mBeforeIndices = new .() ~ delete _;
	private SplatRegion mRegion = .();
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

	public StringView Id => "terrain.splat";
	public StringView DisplayName => "Paint Splat";
	public StringView StatusText => mStatus;

	public uint32 PaletteIndex => mPaletteIndex;
	/// Picking a layer leaves eraser and smooth mode; the palette is unbounded up to what
	/// an eight bit index holds.
	public void SetPaletteIndex(uint32 index)
	{
		mPaletteIndex = Math.Min(index, 255u);
		mErase = false;
		mSmooth = false;
	}

	public bool IsEraser => mErase;
	public void SetEraser(bool erase)
	{
		mErase = erase;
		if (erase)
			mSmooth = false;
	}

	public bool IsSmooth => mSmooth;
	public void SetSmooth(bool smooth)
	{
		mSmooth = smooth;
		if (smooth)
			mErase = false;
	}

	public bool IsAirbrush => mAirbrush;
	public void SetAirbrush(bool airbrush) { mAirbrush = airbrush; }

	public float Radius => mRadius;
	public void SetRadius(float radius)
	{
		mRadius = Math.Clamp(radius, cMinRadius, cMaxRadius);
		if (OnRadiusChanged != null)
			OnRadiusChanged(mRadius);
	}

	public float Strength => mStrength;
	public void SetStrength(float strength) { mStrength = Math.Clamp(strength, 0.0f, 1.0f); }

	public float Spacing => mSpacing;
	public void SetSpacing(float spacing) { mSpacing = Math.Clamp(spacing, 0.05f, 1.0f); }

	public bool IsStroking => mStroking;
	public bool HasHover => mHasHover;

	/// Any terrain in the scene with resolved, non empty weights AND heightfield: the
	/// heightfield is what the ray hits.
	public StringView UnavailableReason =>
		"Paint Splat needs a terrain whose splatmap and heightfield resolve.";

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
					if (any)
						return;
					let res = component.Terrain.Get;
					if (res == null)
						return;
					let weights = res.Weights.Get;
					let grid = res.Heightfield.Get;
					if ((weights != null) && !weights.IsEmpty && (grid != null) && !grid.IsEmpty)
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
			if (kb.IsKeyPressed(.Num1)) SetPaletteIndex(0);
			if (kb.IsKeyPressed(.Num2)) SetPaletteIndex(1);
			if (kb.IsKeyPressed(.Num3)) SetPaletteIndex(2);
			if (kb.IsKeyPressed(.Num4)) SetPaletteIndex(3);
			if (kb.IsKeyPressed(.Num5)) SetPaletteIndex(4);
			if (kb.IsKeyPressed(.Num6)) SetPaletteIndex(5);
			if (kb.IsKeyPressed(.Num7)) SetPaletteIndex(6);
			if (kb.IsKeyPressed(.Num8)) SetPaletteIndex(7);
			if (kb.IsKeyPressed(.Num9)) SetPaletteIndex(8);
			if (kb.IsKeyPressed(.Num0)) SetEraser(true);
			if (kb.IsKeyPressed(.Minus)) SetSmooth(true);
		}
		if (input.PointerOver && (input.WheelDelta != 0.0f))
			SetRadius(mRadius * (1.0f + 0.12f * input.WheelDelta));

		let pick = ResolvePick(input);
		if (pick.Valid)
		{
			mHasHover = true;
			mHoverWorld = pick.WorldHit;
			mHoverNormal = pick.WorldNormal;
		}

		var consumed = mStroking;
		if (!input.EditingLocked) // Simulate: the splatmap feeds the live material, so no edits
		{
			if (!mStroking && pick.Valid && input.PointerOver && input.LeftPressed)
			{
				BeginStroke(pick);
				consumed = true;
			}
			else if (mStroking && input.LeftDown && pick.Valid && (pick.Weights.Get === mStrokeWeights.Get))
			{
				AdvanceStroke(pick, input.DeltaSeconds);
				consumed = true;
			}
			if (mStroking && (input.LeftReleased || !input.PointerValid))
				EndStroke();
		}
		else if (mStroking)
			EndStroke();

		UpdateStatus();
		return consumed;
	}

	public void Draw(DebugDraw drawList)
	{
		if (!mHasHover)
			return;
		var ring = Color(0.95f, 0.95f, 0.95f, 1.0f);
		if (mSmooth)
			ring = .(0.55f, 0.75f, 0.95f, 1.0f);
		else if (!mErase)
			ring = LayerRingColor(mPaletteIndex);
		drawList.DrawCircleNormal(mHoverWorld, mRadius, mHoverNormal, ring, 40, true);
		drawList.DrawCircleNormal(mHoverWorld, mRadius * 0.5f, mHoverNormal, .(ring.R, ring.G, ring.B, 0.5f), 32, true);
	}

	/// A hue per palette layer, spread round the wheel so neighbouring layers differ.
	public static Color LayerRingColor(uint32 paletteIndex)
	{
		let hue = (float)((paletteIndex * 47u) % 360u) / 360.0f;
		let h6 = hue * 6.0f;
		let x = 1.0f - Math.Abs(h6 - (float)(2 * ((int32)h6 / 2)) - 1.0f);
		float[3][3] comp = .(.(1, x, 0), .(x, 1, 0), .(0, 1, x));
		let seg = Math.Min((int32)h6 / 2, 2);
		return .(0.3f + 0.7f * comp[seg][0], 0.3f + 0.7f * comp[seg][1], 0.3f + 0.7f * comp[seg][2], 1.0f);
	}

	/// The nearest terrain the ray hits, as a raster UV.
	private SplatPick ResolvePick(in ViewportToolInput input)
	{
		var best = SplatPick();
		let manager = (mScene != null) ? mScene.GetSystem<TerrainComponentManager>() : null;
		if (manager == null)
			return best;
		let rayOrigin = input.Ray.Origin;
		let rayDirection = input.Ray.Direction;
		var bestDistance = float.MaxValue;
		manager.ForEach(scope [&] (component, owner) =>
			{
				let res = component.Terrain.Get;
				if (res == null)
					return;
				let weights = res.Weights.Get;
				let grid = res.Heightfield.Get;
				if ((weights == null) || weights.IsEmpty || (grid == null) || grid.IsEmpty)
					return;
				let world = mScene.GetWorldMatrix(owner);
				let inv = Inverse(world);
				let localOrigin = TransformPoint(rayOrigin, inv);
				let localDir = TransformDirection(rayDirection, inv);
				float t = 0.0f;
				if (!grid.QueryRay(localOrigin, localDir, out t))
					return;
				let localHit = localOrigin + Normalized(localDir) * t;
				let worldHit = TransformPoint(localHit, world);
				let distance = Length(worldHit - rayOrigin);
				if (distance >= bestDistance)
					return;
				let ws = grid.WorldSize;
				let sizeX = (ws.X != 0.0f) ? ws.X : 1.0f;
				let sizeY = (ws.Y != 0.0f) ? ws.Y : 1.0f;
				bestDistance = distance;
				best.Weights = res.Weights;
				best.UvX = localHit.X / sizeX + 0.5f;
				best.UvY = localHit.Z / sizeY + 0.5f;
				best.WorldSizeX = sizeX;
				best.WorldSizeY = sizeY;
				best.WorldHit = worldHit;
				best.WorldNormal = Normalized(TransformDirection(grid.GetNormalAt(localHit.X, localHit.Z), world));
				best.Valid = true;
			});
		return best;
	}

	private void BeginStroke(in SplatPick pick)
	{
		mStroking = true;
		mStrokeWeights = pick.Weights;
		let weights = mStrokeWeights.Get;
		mBeforeWeights.Clear();
		mBeforeWeights.AddRange(weights.Weights);
		mBeforeIndices.Clear();
		mBeforeIndices.AddRange(weights.Indices);
		mRegion = .();
		mAirbrushClock = 0.0f;
		ApplyStamp(pick.UvX, pick.UvY, pick, mStrength);
		mLastStampU = pick.UvX;
		mLastStampV = pick.UvY;
	}

	/// Walks stamps from the last one toward the pointer at the spacing, the remainder
	/// carrying to the next frame; airbrush adds time cadence stamps at the pointer.
	private void AdvanceStroke(in SplatPick pick, float deltaSeconds)
	{
		if (mStrokeWeights.Get == null)
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

	private void ApplyStamp(float uvX, float uvY, in SplatPick pick, float amount)
	{
		let weights = mStrokeWeights.Get;
		if (weights == null)
			return;
		let uvRadiusX = mRadius / pick.WorldSizeX;
		let uvRadiusY = mRadius / pick.WorldSizeY;
		let t = Math.Clamp(amount, 0.0f, 1.0f);
		let core = 0.5f * t;
		SplatRegion r;
		if (mSmooth)
			r = SplatBrush.Smooth(weights, uvX, uvY, uvRadiusX, uvRadiusY, t, core);
		else if (mErase)
			r = SplatBrush.Erase(weights, uvX, uvY, uvRadiusX, uvRadiusY, t, core);
		else
			r = SplatBrush.Paint(weights, uvX, uvY, uvRadiusX, uvRadiusY, mPaletteIndex, t, core);
		if (!r.IsEmpty)
		{
			mRegion.Add(r.MinX, r.MinY);
			mRegion.Add(r.MaxX, r.MaxY);
		}
	}

	private void EndStroke()
	{
		let weights = mStrokeWeights.Get;
		if (mStroking && (weights != null) && !mRegion.IsEmpty)
		{
			let rasterW = weights.Width;
			let beforeW = scope List<uint8>();
			let afterW = scope List<uint8>();
			let beforeI = scope List<uint8>();
			let afterI = scope List<uint8>();
			SplatStrokeCommand.SliceRegion(mBeforeWeights, rasterW, mRegion, beforeW);
			SplatStrokeCommand.SliceRegion(weights.Weights, rasterW, mRegion, afterW);
			SplatStrokeCommand.SliceRegion(mBeforeIndices, rasterW, mRegion, beforeI);
			SplatStrokeCommand.SliceRegion(weights.Indices, rasterW, mRegion, afterI);
			mCommands.Execute(new SplatStrokeCommand(mStrokeWeights, mRegion, beforeW, afterW, beforeI, afterI));
			if ((mAssetEdits != null) && mStrokeWeights.Id.IsSet)
				mAssetEdits.RegisterAssetEdit(mStrokeWeights.Id, TerrainPersist.ForSplat(weights, mStrokeWeights.Id));
		}
		mStroking = false;
		mStrokeWeights = default;
		mBeforeWeights.Clear();
		mBeforeIndices.Clear();
		mRegion = .();
	}

	private void UpdateStatus()
	{
		let radius = (int32)(mRadius + 0.5f);
		if (mSmooth)
			mStatus.Set(scope $"Paint Splat [SMOOTH]  radius {radius}  (1-9 layer, 0 eraser, - smooth, wheel size)");
		else if (mErase)
			mStatus.Set(scope $"Paint Splat [ERASER]  radius {radius}  (1-9 layer, 0 eraser, - smooth, wheel size)");
		else
			mStatus.Set(scope $"Paint Splat [layer {mPaletteIndex}]  radius {radius}  (1-9 layer, 0 eraser, - smooth, wheel size)");
	}
}
