using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Moves every bone attachment to its bone, in PostUpdate after the animators whose palettes it
/// reads, through the animator's model entity (the first mesh entity, as IK uses it).
///
/// SIMULATION GATED: standing still, the animators hold the rest pose, which is where the bone's
/// node stands already; writing it there each frame would only fight the editor's own edits.
class BoneAttachmentComponentManager : SerializableComponentManager<BoneAttachmentComponent>
{
	private struct Pending
	{
		public BoneAttachmentComponent* Component;
		public EntityHandle Owner;
		public uint32 Depth;
	}

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	private List<Pending> mOrder = new .() ~ delete _;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	public ~this()
	{
		mScene = null;
	}

	public override bool IsSimulationOnly => true;
	/// After the animation graph (-1) and single clip (0) managers, whose palettes it reads.
	public override int32 UpdateOrder => 1;

	protected override void OnComponentCreated(BoneAttachmentComponent* component, EntityHandle entity)
	{
		component.Bone = new String();
		component.Runtime = new BoneAttachmentRuntime();
	}

	protected override void OnComponentDestroyed(BoneAttachmentComponent* component, EntityHandle entity)
	{
		DeleteAndNullify!(component.Runtime);
		DeleteAndNullify!(component.Bone);
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;
		using (ProfileScope("Animation.BoneAttachment"))
		{
			// Shallowest first: an attachment under another composes its parent's world from the
			// transform this frame just set (a hand's, then a finger's). An insertion sort keeps
			// equal depths in pool order.
			mOrder.Clear();
			ForEach(scope (component, owner) =>
				{
					uint32 depth = 0;
					for (var e = mScene.GetParent(owner); mScene.IsValid(e) && (depth < 1024); e = mScene.GetParent(e))
						depth++;
					mOrder.Add(.() { Component = component, Owner = owner, Depth = depth });
				});
			for (int i = 1; i < mOrder.Count; i++)
			{
				let p = mOrder[i];
				var j = i;
				for (; (j > 0) && (mOrder[j - 1].Depth > p.Depth); j--)
					mOrder[j] = mOrder[j - 1];
				mOrder[j] = p;
			}
			for (let p in mOrder)
				Follow(p.Component, p.Owner);
		}
	}

	/// The palette of the animator on `animator` (a graph before a single clip, as they tick),
	/// empty until its player has posed.
	private Span<Float4x4> Palette(EntityHandle animator)
	{
		if (let graphs = mScene.GetSystem<AnimationGraphComponentManager>())
		{
			if (let graph = graphs.Get(animator))
				return (graph.Player != null) ? graph.Player.GetSkinningMatrices() : default;
		}
		if (let clips = mScene.GetSystem<SkeletalAnimationComponentManager>())
		{
			if (let clip = clips.Get(animator))
				return (clip.Player != null) ? clip.Player.GetSkinningMatrices() : default;
		}
		return default;
	}

	private void Off(BoneAttachmentComponent* component, EntityHandle owner, BoneAttachmentStatus status, StringView detail)
	{
		let runtime = component.Runtime;
		runtime.Status = status;
		if (runtime.Logged != status)
		{
			runtime.Logged = status;
			GlobalLog(.Warning, "Animation: bone attachment on '{}' is off: {}", mScene.GetEntityName(owner), detail);
		}
	}

	private void Follow(BoneAttachmentComponent* component, EntityHandle owner)
	{
		let runtime = component.Runtime;
		if (runtime == null)
			return;
		let found = IkScene.FindAnimator(mScene, owner, let animator);
		if (found != .Found)
		{
			Off(component, owner, .NoAnimator, (found == .Ambiguous)
				? "several animators below it, none above" : "no animator at, above or below it");
			return;
		}
		let palette = Palette(animator.Entity);
		if ((animator.Skeleton == null) || palette.IsEmpty)
		{
			runtime.Status = .Waiting; // the player poses on its first tick
			return;
		}
		if (runtime.ResolvedFor !== animator.Skeleton)
		{
			runtime.ResolvedFor = animator.Skeleton;
			runtime.BoneIndex = animator.Skeleton.FindBone(component.Bone);
			let bone = (runtime.BoneIndex >= 0) ? animator.Skeleton.GetBone(runtime.BoneIndex) : null;
			runtime.BindModel = (bone != null) ? Inverse(bone.InverseBindPose) : Float4x4.Identity();
		}
		if ((runtime.BoneIndex < 0) || (runtime.BoneIndex >= palette.Length))
		{
			Off(component, owner, .UnknownBone, "its bone is not in the animator's skeleton");
			return;
		}
		runtime.Status = .Following;
		runtime.Logged = .Following;

		// The palette is the inverse bind times the bone's model pose (row vectors), so the bind
		// pose undoes it; the model entity's world (composed fresh: the cached world matrices
		// update after PostUpdate) takes it to the world, the parent's inverse to the local.
		let boneModel = runtime.BindModel * palette[runtime.BoneIndex];
		let world = boneModel * mScene.ComposeWorldMatrix(animator.ModelEntity);
		let parent = mScene.GetParent(owner);
		let local = mScene.IsValid(parent) ? (world * Inverse(mScene.ComposeWorldMatrix(parent))) : world;
		mScene.SetLocalTransform(owner, Transform.FromMatrix(local));
	}
}
