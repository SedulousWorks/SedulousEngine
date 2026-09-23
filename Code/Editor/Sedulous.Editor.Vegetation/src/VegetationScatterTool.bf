using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Vegetation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Vegetation;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The prop brush: it stamps authored instances into a Scattered layer of the terrain's
/// vegetation component, or erases the ones under the disc.
///
/// A stamp is the pure ScatterStamp: density times the disc's area in candidates scaled by
/// the strength, the layer's own slope, height, scale and alignment rules, a spacing rule
/// against the props already there, and a collision query, which is the scene's physics
/// world with the terrain's own body excluded, since every stamp sits on it.
///
/// One command per stroke, holding the layer's instances before and after, and the
/// instances persist on the component with the scene. DETERMINISTIC per stroke: the stamp
/// seeds count up from the stroke's start, so a scripted stroke places the same props every
/// run.
///
/// The scene and the command stack are BORROWED from the host.
class VegetationScatterTool : IViewportTool
{
	public const float cMinRadius = 0.5f;
	public const float cMaxRadius = 128.0f;
	private const float cMinStampSpacing = 0.1f;
	/// Teleport guard: alt-tab warps and huge drags.
	private const int32 cMaxStampsPerFrame = 1024;

	/// Where a prop may NOT go, in WORLD space. Null falls back to the scene's physics world,
	/// or to nothing when the scene has none.
	public typealias BlockedQuery = delegate bool(Float3 worldPosition, float radius);

	private Scene mScene;
	private EditorCommandStack mCommands;

	private uint32 mLayer = 0;
	private bool mErase = false;
	/// World units.
	private float mRadius = 6.0f;
	/// Props per square metre a full strength stamp tries for.
	private float mDensity = 0.25f;
	/// Coverage per stamp, nought to one: a scrub builds a field up gently.
	private float mStrength = 1.0f;
	/// The minimum gap between props, as a multiple of the mesh's radius; nought is none.
	private float mSpacing = 1.0f;
	/// Stamp spacing along the stroke, as a fraction of the radius.
	private float mStampSpacing = 0.5f;
	/// An override for tests and for a host with its own occupancy. Owned.
	private BlockedQuery mBlockedOverride = null ~ delete _;

	private bool mHasHover = false;
	private Float3 mHoverWorld = .Zero;
	private Float3 mHoverNormal = .(0.0f, 1.0f, 0.0f);

	private bool mStroking = false;
	private EntityHandle mStrokeOwner = .();
	private uint32 mStrokeLayer = 0;
	/// The stamp's seed within the stroke, and the stroke's within the session.
	private uint32 mStrokeStamps = 0;
	private uint32 mStrokeCount = 0;
	private Float3 mLastStampLocal = .Zero;
	private List<Float4x4> mBefore = new .() ~ delete _;
	private List<Float4x4> mPlaced = new .() ~ delete _;
	private List<BodyId> mOverlapScratch = new .() ~ delete _;
	private String mStatus = new .() ~ delete _;

	/// The panel's radius readout follows wheel sizing through this. Owned.
	public delegate void(float radius) OnRadiusChanged = null ~ delete _;

	public this(Scene scene, EditorCommandStack commands)
	{
		mScene = scene;
		mCommands = commands;
		UpdateStatus();
	}

	public StringView Id => "vegetation.scatter";
	public StringView DisplayName => "Paint Props";
	public StringView StatusText => mStatus;

	public uint32 Layer => mLayer;
	/// Picking a layer leaves the eraser.
	public void SetLayer(uint32 index)
	{
		mLayer = index;
		mErase = false;
		UpdateStatus();
	}

	public bool IsEraser => mErase;
	public void SetEraser(bool on)
	{
		mErase = on;
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

	public float Density => mDensity;
	public void SetDensity(float density) { mDensity = Math.Clamp(density, 0.0f, 64.0f); }

	public float Strength => mStrength;
	public void SetStrength(float strength) { mStrength = Math.Clamp(strength, 0.0f, 1.0f); }

	public float Spacing => mSpacing;
	public void SetSpacing(float spacing) { mSpacing = Math.Clamp(spacing, 0.0f, 8.0f); }

	public float StampSpacing => mStampSpacing;
	public void SetStampSpacing(float spacing)
	{
		mStampSpacing = Math.Clamp(spacing, cMinStampSpacing, 2.0f);
	}

	/// CONSUMES `query`, and replaces whatever was there.
	public void SetBlockedQuery(BlockedQuery query)
	{
		delete mBlockedOverride;
		mBlockedOverride = query;
	}

	public bool IsStroking => mStroking;
	public bool HasHover => mHasHover;

	/// A footprint over a terrain AND at least one Scattered layer to paint into: without
	/// one there is nothing this brush can do.
	public bool IsAvailable
	{
		get
		{
			if (!VegetationPick.AnyFootprint(mScene, false))
				return false;

			let manager = mScene.GetSystem<TerrainVegetationComponentManager>();
			if (manager == null)
				return false;

			var any = false;
			manager.ForEach(scope [&] (component, owner) =>
				{
					if (component.Layers == null)
						return;
					for (let layer in component.Layers)
						any |= layer.Placement == .Scattered;
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
			if (kb.IsKeyPressed(.Num1)) SetLayer(0);
			if (kb.IsKeyPressed(.Num2)) SetLayer(1);
			if (kb.IsKeyPressed(.Num3)) SetLayer(2);
			if (kb.IsKeyPressed(.Num4)) SetLayer(3);
			if (kb.IsKeyPressed(.Num5)) SetLayer(4);
			if (kb.IsKeyPressed(.Num6)) SetLayer(5);
			if (kb.IsKeyPressed(.Num7)) SetLayer(6);
			if (kb.IsKeyPressed(.Num8)) SetLayer(7);
			if (kb.IsKeyPressed(.Num9)) SetLayer(8);
			if (kb.IsKeyPressed(.Num0)) SetEraser(true);
		}
		if (input.PointerOver && (input.WheelDelta != 0.0f))
			SetRadius(mRadius * (1.0f + 0.12f * input.WheelDelta));

		let pick = VegetationPick.Resolve(mScene, input.Ray.Origin, input.Ray.Direction, false);
		if (pick.Valid)
		{
			mHasHover = true;
			mHoverWorld = pick.WorldHit;
			mHoverNormal = pick.WorldNormal;
		}

		var consumed = mStroking;
		// Simulate: the props feed the live scene, so no edits.
		if (!input.EditingLocked)
		{
			if (!mStroking && Paintable(pick) && input.PointerOver && input.LeftPressed)
			{
				BeginStroke(pick, input);
				consumed = true;
			}
			else if (mStroking && input.LeftDown && pick.Valid && (pick.Owner == mStrokeOwner))
			{
				AdvanceStroke(pick, input);
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

		let ring = mErase ? Color(0.95f, 0.95f, 0.95f, 1.0f) : Color(0.85f, 0.6f, 0.2f, 1.0f);
		drawList.DrawCircleNormal(mHoverWorld, mRadius, mHoverNormal, ring, 40, true);
		drawList.DrawCircleNormal(mHoverWorld, mRadius * 0.5f, mHoverNormal,
			.(ring.R, ring.G, ring.B, 0.5f), 32, true);
	}

	/// The selected slot exists and is a Scattered layer: anything else is a layer this
	/// brush has no business writing into.
	private bool Paintable(in VegetationPick pick)
	{
		let layer = LayerAt(pick, mLayer);
		return (layer != null) && (layer.Placement == .Scattered);
	}

	private static VegetationLayer LayerAt(in VegetationPick pick, uint32 index)
	{
		if (!pick.Valid || (pick.Component == null) || (pick.Component.Layers == null)
			|| ((int)index >= pick.Component.Layers.Count))
			return null;
		return pick.Component.Layers[(int)index];
	}

	private void BeginStroke(in VegetationPick pick, in ViewportToolInput input)
	{
		let layer = LayerAt(pick, mLayer);
		if (layer == null)
			return;

		mStroking = true;
		mStrokeOwner = pick.Owner;
		mStrokeLayer = mLayer;
		mStrokeStamps = 0;
		mBefore.Clear();
		mBefore.AddRange(layer.Instances);
		ApplyStamp(pick, pick.LocalHit);
		mLastStampLocal = pick.LocalHit;
	}

	/// Walks stamps from the last one toward the pointer at the stamp spacing, in TERRAIN
	/// LOCAL metres, so a fast drag leaves no gaps.
	private void AdvanceStroke(in VegetationPick pick, in ViewportToolInput input)
	{
		let spacing = Math.Max(mRadius * mStampSpacing, 1.0e-3f);
		for (int32 i < cMaxStampsPerFrame)
		{
			let dx = pick.LocalHit.X - mLastStampLocal.X;
			let dz = pick.LocalHit.Z - mLastStampLocal.Z;
			let distance = Math.Sqrt(dx * dx + dz * dz);
			if (distance < spacing)
				break; // no partial stamps

			let f = spacing / distance;
			mLastStampLocal.X += dx * f;
			mLastStampLocal.Z += dz * f;
			mLastStampLocal.Y = pick.Heightfield.GetHeightAt(mLastStampLocal.X, mLastStampLocal.Z);
			ApplyStamp(pick, mLastStampLocal);
		}
	}

	private void ApplyStamp(in VegetationPick pick, Float3 localCentre)
	{
		let layer = LayerAt(pick, mStrokeLayer);
		if (layer == null)
			return;

		if (mErase)
		{
			Scatter.EraseInstancesInDisc(layer.Instances, localCentre.X, localCentre.Z, mRadius);
			mStrokeStamps++;
			return;
		}

		let terrainWorld = pick.TerrainWorld;
		Scatter.BlockedQuery blocked = null;
		if (mBlockedOverride != null)
		{
			// The override speaks WORLD space, as the physics world does.
			let query = mBlockedOverride;
			blocked = scope:: [&] (local, radius) =>
				query(TransformPoint(local, terrainWorld), radius);
		}
		else
		{
			let physics = mScene.GetSystem<PhysicsSceneSystem>();
			let world = (physics != null) ? physics.World : null;
			if (world != null)
			{
				let terrain = pick.TerrainEntity;
				let owner = pick.Owner;
				let bodies = mOverlapScratch;
				blocked = scope:: [&] (local, radius) =>
					{
						var sphere = QueryShape();
						sphere.Kind = .Sphere;
						sphere.Radius = radius;
						// Lifted by the radius so the sphere sits ON the ground rather than
						// half buried in the terrain body.
						let centre = TransformPoint(local, terrainWorld) + Float3(0.0f, radius, 0.0f);
						world.ShapeOverlap(sphere, centre, Quaternion.Identity, bodies);
						for (let body in bodies)
						{
							let e = PhysicsEntityPacking.UnpackEntity(world.UserData(body));
							// The terrain itself is what every prop stands on.
							if ((e != terrain) && (e != owner))
								return true;
						}
						return false;
					};
			}
		}

		let mesh = layer.Mesh.Get;
		let meshBounds = (mesh != null) ? mesh.Bounds : AABB.Empty();
		var stamps = mStrokeStamps;
		var strokes = mStrokeCount;
		let seed = HashBytes(&stamps, sizeof(uint32),
			HashBytes(&strokes, sizeof(uint32), 0x5EED));

		mPlaced.Clear();
		Scatter.ScatterStamp(seed, pick.Heightfield, layer.ToScatterLayer(), meshBounds,
			localCentre.X, localCentre.Z, mRadius, mDensity, mStrength, mSpacing,
			layer.Instances, blocked, mPlaced);
		layer.Instances.AddRange(mPlaced);
		mStrokeStamps++;
	}

	private void EndStroke()
	{
		if (mStroking)
		{
			let manager = (mScene != null)
				? mScene.GetSystem<TerrainVegetationComponentManager>() : null;
			let component = (manager != null) ? manager.Get(mStrokeOwner) : null;
			if ((component != null) && (component.Layers != null)
				&& ((int)mStrokeLayer < component.Layers.Count))
			{
				let after = component.Layers[(int)mStrokeLayer].Instances;
				var changed = after.Count != mBefore.Count;
				if (!changed && !after.IsEmpty)
				{
					changed = Internal.MemCmp(after.Ptr, mBefore.Ptr,
						after.Count * strideof(Float4x4)) != 0;
				}
				if (changed)
				{
					mCommands.Execute(new ScatterStrokeCommand(mScene, mStrokeOwner, mStrokeLayer,
						mBefore, after));
				}
			}
			mStrokeCount++;
		}

		mStroking = false;
		mStrokeOwner = .();
		mBefore.Clear();
	}

	private void UpdateStatus()
	{
		let radius = (int32)(mRadius + 0.5f);
		let keys = "(1-9 layer, 0 eraser, wheel size)";
		if (mErase)
			mStatus.Set(scope $"Paint Props [ERASER]  radius {radius}  {keys}");
		else
			mStatus.Set(scope $"Paint Props [layer {mLayer}]  radius {radius}  {keys}");
	}
}
