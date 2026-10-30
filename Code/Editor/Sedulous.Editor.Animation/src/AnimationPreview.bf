using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Animation;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Preview;

namespace Sedulous.Editor.Animation;

// What the animation pages' previews share (Raptor's editor-gui spec, 5.4, layer 10): a skeleton
// drawn as its bones (a line from each to its parent, a cross at each joint, one bone drawn apart from
// the rest when chosen), the path a clip's root motion travels drawn on the ground, and the rig a pose
// is shown on (AnimationPreviewRig): the skeleton and the skinned mesh the preview plays on, picked on
// the preview's bar, each optional (no mesh: the bones alone), the mesh skinned with the pose each
// frame.

static class AnimationPreview
{
	/// `skeleton` in the pose `localPoses` as its bones, placed by `placement`; `chosen` (-1: none)
	/// drawn apart. `worldScratch` is the caller's, kept between frames; it holds every bone's world
	/// matrix after.
	public static void DrawSkeletonBones(DebugDraw draw, Skeleton skeleton, Span<BoneTransform> localPoses,
		List<Float4x4> worldScratch, Float4x4 placement, int32 chosen = -1)
	{
		let boneCount = skeleton.BoneCount;
		if ((boneCount == 0) || (localPoses.Length < boneCount))
			return;
		worldScratch.Count = boneCount;
		skeleton.ComputeWorldPoses(localPoses, .(worldScratch.Ptr, boneCount));
		for (int b < boneCount)
			worldScratch[b] = worldScratch[b] * placement;
		let boneColor = Color(0.35f, 0.85f, 1.0f, 1.0f);
		let chosenColor = Color(1.0f, 0.78f, 0.25f, 1.0f);
		for (int32 b < boneCount)
		{
			let bone = skeleton.GetBone(b);
			let isChosen = b == chosen;
			let color = isChosen ? chosenColor : boneColor;
			let joint = JointPosition(worldScratch[b]);
			if ((bone != null) && (bone.ParentIndex >= 0) && (bone.ParentIndex < boneCount))
				draw.DrawLine(JointPosition(worldScratch[bone.ParentIndex]), joint, color, isChosen);
			draw.DrawCross(joint, isChosen ? 0.05f : 0.02f, color);
		}
	}

	public static Float3 JointPosition(in Float4x4 world) => .(world.M[3][0], world.M[3][1], world.M[3][2]);

	/// The path `clip`'s root motion travels from its start (on the ground, and up where it takes its
	/// height), and where the clip is along it at `time`. Nothing for a clip without one.
	public static void DrawRootMotionPath(DebugDraw draw, AnimationClip clip, float time)
	{
		let curve = clip.RootMotion;
		if (curve.IsEmpty)
			return;
		let path = Color(1.0f, 0.75f, 0.2f, 1.0f);
		let start = curve.Positions[0];
		Float3 OnGround(Float3 p) => .(curve.Horizontal ? (p.X - start.X) : 0.0f, curve.Vertical ? (p.Y - start.Y) : 0.0f,
			curve.Horizontal ? (p.Z - start.Z) : 0.0f);
		for (int i = 0; (i + 1) < curve.Positions.Count; i++)
			draw.DrawLine(OnGround(curve.Positions[i]), OnGround(curve.Positions[i + 1]), path, true);
		let now = RootMotion.ClipRootMotion(clip, 0.0f, time, false);
		draw.DrawWireSphere(now.Translation, 0.04f, path, 10, true);
	}

	/// `pane`'s camera put where the bones at `world` (their model-space matrices, as
	/// DrawSkeletonBones leaves them) fill the view: a skeleton may be a few centimetres tall or a
	/// hundred metres. False without a preview or bones.
	public static bool FrameBones(PreviewPane pane, Span<Float4x4> world)
	{
		let preview = (pane != null) ? pane.Viewport : null;
		if ((preview == null) || world.IsEmpty)
			return false;
		var low = JointPosition(world[0]);
		var high = low;
		for (let bone in world)
		{
			let at = JointPosition(bone);
			low = .(Math.Min(low.X, at.X), Math.Min(low.Y, at.Y), Math.Min(low.Z, at.Z));
			high = .(Math.Max(high.X, at.X), Math.Max(high.Y, at.Y), Math.Max(high.Z, at.Z));
		}
		// From the front and a little above, far enough that the tallest side fills about two thirds.
		let middle = (low + high) * 0.5f;
		let size = Math.Max(Math.Max(high.X - low.X, high.Y - low.Y), Math.Max(high.Z - low.Z, 0.01f));
		let distance = size * 1.6f;
		let camera = preview.Camera;
		camera.Position = middle + Normalized(Float3(0.35f, 0.3f, 1.0f)) * distance;
		camera.LookAt(middle);
		camera.NearZ = Math.Min(camera.NearZ, distance * 0.05f);
		camera.FarZ = Math.Max(camera.FarZ, distance * 4.0f);
		return true;
	}

	/// Where the rig stands at `time` when it travels by `clip`'s root motion from its start.
	public static Float4x4 RootMotionPlacement(AnimationClip clip, float time)
	{
		if (clip.RootMotion.IsEmpty)
			return .Identity();
		let moved = RootMotion.ClipRootMotion(clip, 0.0f, time, false);
		return Transform(moved.Translation, Quaternion.FromAxisAngle(.(0, 1, 0), moved.Yaw), .(1, 1, 1)).ToMatrix();
	}
}

/// The skeleton and the skinned mesh a preview shows a pose on, picked on its bar.
class AnimationPreviewRig
{
	/// Borrowed: the page's, which outlive the rig.
	private EditorContext mContext;
	private AssetPageServices mServices;
	private PreviewPane mPane;
	// The pane's bar holds a reference of its own; these are ours.
	private AssetPickerSlot mSkeletonSlot = null ~ _?.ReleaseRef();
	private AssetPickerSlot mMeshSlot = null ~ _?.ReleaseRef();
	private Guid mSkeletonId = .();
	private Guid mMeshId = .();
	private Proxy<Skeleton> mSkeleton = default;
	private Proxy<StaticMesh> mMesh = default;
	/// The product the entity draws, as last pointed.
	private StaticMesh mShownMesh = null;
	private EntityHandle mMeshEntity = .Invalid;
	private List<BoneTransform> mBind = new .() ~ delete _;
	private List<Float4x4> mWorld = new .() ~ delete _;
	private List<Float4x4> mSkinning = new .() ~ delete _;
	/// The skeleton the first frame was told for.
	private Skeleton mFramedFor = null;
	private delegate void() mOnPicked ~ delete _;
	private delegate void() mOnFirstShown ~ delete _;

	/// Over `pane`'s preview (its scene given a sun and the mesh's entity), its two slots placed
	/// among the preview's own choices. Without a preview (a test), it still keeps what was picked.
	public this(EditorContext context, AssetPageServices services, PreviewPane pane)
	{
		mContext = context;
		mServices = services;
		mPane = pane;
		// The slots: what makes a skeleton, asked of the builders; a skinned mesh's asset, by its type.
		mSkeletonSlot = MakeSlot("preview-skeleton", "The skeleton the preview plays on; kept for this asset", true);
		mSkeletonSlot.AcceptTypesOf(services.Refs, typeof(Skeleton));
		mMeshSlot = MakeSlot("preview-mesh", "The skinned mesh drawn over the skeleton (none: the bones alone); kept for this asset", false);
		StringView[1] meshes = .("SkinnedMeshAsset");
		mMeshSlot.SetAcceptedTypes(meshes);
		Labelled("Skeleton", mSkeletonSlot);
		Labelled("Mesh", mMeshSlot);

		let scene = (pane.Viewport != null) ? pane.Viewport.Scene : null;
		if (scene == null)
			return;
		// A sun so a skinned mesh is lit (the bones need none), and the mesh's entity, drawing nothing
		// until one is picked.
		let sun = scene.CreateEntity("Sun");
		var t = Transform();
		t.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.35f) * Quaternion.FromAxisAngle(.(1, 0, 0), -1.05f);
		scene.SetLocalTransform(sun, t);
		if (let lights = scene.GetSystem<LightComponentManager>())
			lights.Add(sun).CastsShadows = false;
		mMeshEntity = scene.CreateEntity("PreviewMesh");
		if (let components = scene.GetSystem<MeshComponentManager>())
			components.Add(mMeshEntity);
		pane.Viewport.Camera.Position = .(0.0f, 1.4f, 3.2f);
		pane.Viewport.Camera.LookAt(.(0.0f, 0.9f, 0.0f));
	}

	public ~this()
	{
		// The entity lets go of the pose's matrices before they go.
		PointMeshAt(null);
		mSkeleton.Forget();
		mMesh.Forget();
	}

	/// The skeleton it plays on (empty: none) and the skinned mesh drawn over it (empty: the bones
	/// alone), each bound by its asset's id.
	public void SetSkeleton(Guid id)
	{
		mSkeletonId = id;
		mSkeleton.Forget();
		mSkeleton = default;
		if ((mContext.Resources != null) && !id.IsNil)
		{
			mSkeleton = mContext.Resources.Bind<Skeleton>(id);
			mSkeleton.Retain();
		}
		ShowSlot(mSkeletonSlot, id);
	}

	public void SetMesh(Guid id)
	{
		mMeshId = id;
		mMesh.Forget();
		mMesh = default;
		if ((mContext.Resources != null) && !id.IsNil)
		{
			mMesh = mContext.Resources.Bind<StaticMesh>(id);
			mMesh.Retain();
		}
		PointMeshAt(null); // pointed at the product once it resolves (Show)
		ShowSlot(mMeshSlot, id);
	}

	public Guid SkeletonId => mSkeletonId;
	public Guid MeshId => mMeshId;
	/// The cooked skeleton (null: none picked, or not cooked yet).
	public Skeleton CookedSkeleton => mSkeleton.Get;

	/// Told when the user picks either: the page keeps them with the project. OWNERSHIP transfers.
	public void SetOnPicked(delegate void() picked)
	{
		delete mOnPicked;
		mOnPicked = picked;
	}

	/// Told once, the first time a skeleton shows (the page frames it). OWNERSHIP transfers.
	public void SetOnFirstShown(delegate void() shown)
	{
		delete mOnFirstShown;
		mOnFirstShown = shown;
	}

	/// Once a frame: `pose` (the skeleton's local poses; empty or short: its bind pose) shown, placed
	/// by `placement`, its bones drawn (`chosen` apart) and the mesh skinned with it.
	public void Show(Span<BoneTransform> pose, Float4x4 placement, int32 chosen = -1)
	{
		let preview = mPane.Viewport;
		if ((preview == null) || !preview.IsValid)
			return;
		let draw = preview.SceneDebugDraw;
		draw.DrawGrid(.(0.0f, 0.0f, 0.0f), 4.0f, 8, .(0.25f, 0.25f, 0.28f, 1.0f));

		// The mesh follows its product (a cook or a reload makes a new one).
		let mesh = mMesh.Get;
		if (mesh !== mShownMesh)
			PointMeshAt(mesh);

		let skeleton = CookedSkeleton;
		if ((skeleton == null) || (skeleton.BoneCount <= 0))
			return;
		let boneCount = skeleton.BoneCount;
		var pose;
		if (pose.Length < boneCount)
		{
			mBind.Count = boneCount;
			for (int32 b < boneCount)
				mBind[b] = skeleton.GetBone(b).LocalBindPose;
			pose = mBind;
		}
		AnimationPreview.DrawSkeletonBones(draw, skeleton, pose, mWorld, placement, chosen);
		if ((skeleton !== mFramedFor) && !mWorld.IsEmpty)
		{
			mFramedFor = skeleton;
			if (mOnFirstShown != null)
				mOnFirstShown();
		}

		let component = MeshComponentOf();
		if ((component == null) || (mesh == null))
			return;
		// Skinned with the pose, placed where the bones are (borrowed for this frame's drawing).
		mSkinning.Count = boneCount;
		skeleton.ComputeSkinningMatrices(pose, .(mSkinning.Ptr, boneCount));
		component.BoneMatrices = mSkinning.Ptr;
		component.BoneCount = (uint32)boneCount;
		var placed = Transform();
		placed.Position = .(placement.M[3][0], placement.M[3][1], placement.M[3][2]);
		placed.Rotation = QuaternionFromRotationMatrix(placement);
		preview.Scene.SetLocalTransform(mMeshEntity, placed);
	}

	/// The preview's camera put where the bones last shown fill the view (a skeleton may be a few
	/// centimetres tall or a hundred metres); false when none have shown yet.
	public bool Frame() => AnimationPreview.FrameBones(mPane, mWorld);

	// === For tests ===

	public AssetPickerSlot SkeletonSlot => mSkeletonSlot;
	public AssetPickerSlot MeshSlot => mMeshSlot;

	private void Labelled(StringView text, AssetPickerSlot slot)
	{
		let label = new Sedulous.GUI.Label();
		label.AddClass("preview-hint");
		label.Text = text;
		mPane.AddControl(label);
		label.ReleaseRef(); // the bar's keeps it
		mPane.AddControl(slot);
	}

	private AssetPickerSlot MakeSlot(StringView id, StringView tooltip, bool skeleton)
	{
		let slot = new AssetPickerSlot();
		slot.Id = id;
		slot.AddClass("preview-slot");
		slot.Tooltip = tooltip;
		let refs = mServices.Refs;
		if ((refs != null) && (refs.Pick != null))
		{
			slot.SetOnPick(new [=this, =refs, =slot, =skeleton] () =>
				{
					refs.Pick(slot.AcceptedTypes, skeleton ? mSkeletonId : mMeshId, new [=this, =skeleton] (picked) => { Assign(skeleton, picked); });
				});
		}
		slot.SetOnClear(new [=this, =skeleton] () => { Assign(skeleton, .()); });
		slot.SetOnDropped(new [=this, =skeleton] (dropped) => { Assign(skeleton, dropped); });
		return slot;
	}

	private void Assign(bool skeleton, Guid id)
	{
		if (skeleton)
			SetSkeleton(id);
		else
			SetMesh(id);
		if (mOnPicked != null)
			mOnPicked();
	}

	private void ShowSlot(AssetPickerSlot slot, Guid id)
	{
		if (slot == null)
			return;
		let refs = mServices.Refs;
		if (!id.IsNil && (refs != null) && (refs.Describe != null))
		{
			let shown = scope ResourceRefShown();
			if (refs.Describe(id, shown))
			{
				slot.SetValue(shown.Name);
				slot.SetGlyph(shown.Glyph, shown.GlyphClass);
				return;
			}
		}
		slot.SetValue("");
		slot.SetGlyph("");
	}

	private MeshComponent* MeshComponentOf()
	{
		let scene = (mPane.Viewport != null) ? mPane.Viewport.Scene : null;
		let components = (scene != null) ? scene.GetSystem<MeshComponentManager>() : null;
		return ((components != null) && mMeshEntity.IsAssigned) ? components.Get(mMeshEntity) : null;
	}

	private void PointMeshAt(StaticMesh mesh)
	{
		mShownMesh = mesh;
		let component = MeshComponentOf();
		if (component == null)
			return;
		component.Mesh.SetId(.());
		component.Mesh.SetDirect(mesh); // the product the proxy resolved: the proxy keeps it bound
		component.BoneMatrices = null;
		component.PrevBoneMatrices = null;
		component.BoneCount = 0;
	}
}
