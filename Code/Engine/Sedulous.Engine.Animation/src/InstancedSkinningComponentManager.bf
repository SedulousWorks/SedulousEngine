using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Profiler;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every crowd in the animation phase, before extraction: advance each clip's clock,
/// sample each clip at its phases into its block of the pose pool, and hand the pool to the
/// target sets.
class InstancedSkinningComponentManager : ResourceBindingComponentManager<InstancedSkinningComponent>
{
	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
	}

	/// Simulation gated, for the reason the clip manager gives.
	public override bool IsSimulationOnly => true;

	protected override void OnComponentCreated(InstancedSkinningComponent* component,
		EntityHandle entity)
	{
		component.Clips = new List<Ref<AnimationClip>>();
		component.Targets = new List<EntityRef>();
		component.PosePool = new List<Float4x4>();
		component.PrevPosePool = new List<Float4x4>();
		component.Scratch = new List<BoneTransform>();
		component.Times = new List<float>();
	}

	protected override void OnComponentDestroyed(InstancedSkinningComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.Clips);
		DeleteAndNullify!(component.Targets);
		DeleteAndNullify!(component.PosePool);
		DeleteAndNullify!(component.PrevPosePool);
		DeleteAndNullify!(component.Scratch);
		DeleteAndNullify!(component.Times);
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .PostUpdate) || (mScene == null))
			return;

		let sets = mScene.GetSystem<InstancedMeshComponentManager>();
		if (sets == null)
			return;

		using (ProfileScope("Animation.InstancedSkinning"))
		{
			ForEach(scope (component, owner) =>
				{
					Tick(sets, component, owner, deltaTime);
				});
		}
	}

	private void Tick(InstancedMeshComponentManager sets, InstancedSkinningComponent* component,
		EntityHandle owner, float deltaTime)
	{
		// Frozen.
		if (!mScene.IsEffectivelyActive(owner))
			return;

		let skeleton = component.Skeleton.Get;
		let clipCount = (uint32)component.Clips.Count;
		if ((skeleton == null) || (clipCount == 0) || (component.PoseCount == 0))
			return;

		let boneCount = (uint32)skeleton.BoneCount;
		if (boneCount == 0)
			return;

		component.BoneCount = boneCount;
		let poses = clipCount * component.PoseCount;
		let poolSize = (int)poses * (int)boneCount;

		// Ping pong: last frame's pool becomes this frame's PREVIOUS, which is what the per
		// bone motion vectors read. Nothing is resampled for it.
		let swap = component.PosePool;
		component.PosePool = component.PrevPosePool;
		component.PrevPosePool = swap;

		component.PosePool.Resize(poolSize);
		component.Scratch.Resize((int)boneCount);
		while (component.Times.Count < (int)clipCount)
			component.Times.Add(0.0f);
		if (component.Times.Count > (int)clipCount)
			component.Times.Count = (int)clipCount;

		// Each clip on its own clock, sampled at evenly spaced phases into its block, so the
		// instances on a clip cycle through it together rather than each keeping a clock.
		let scratch = Span<BoneTransform>(component.Scratch.Ptr, component.Scratch.Count);
		for (uint32 k < clipCount)
		{
			let clip = component.Clips[k].Get;
			let duration = ((clip != null) && (clip.Duration > 0.0f)) ? clip.Duration : 1.0f;
			var time = component.Times[k] + deltaTime * component.Speed;
			while (time >= duration)
				time -= duration;
			while (time < 0.0f)
				time += duration;
			component.Times[k] = time;

			for (uint32 index < component.PoseCount)
			{
				let palette = component.PosePool.Ptr + (int)(k * component.PoseCount + index) * (int)boneCount;
				if (clip == null)
				{
					// A clip not loaded (yet): its block holds the bind pose.
					for (int bone < (int)boneCount)
						palette[bone] = Float4x4.Identity();
					continue;
				}

				var phase = time + ((float)index / (float)component.PoseCount) * duration;
				while (phase >= duration)
					phase -= duration;

				AnimationSampler.SampleClip(clip, skeleton, phase, scratch);
				skeleton.ComputeSkinningMatrices(scratch, .(palette, (int)boneCount));
			}
		}

		// The first frame, or a change of the pool's size: there is no previous pool, so it becomes
		// the current one and the motion reads as zero rather than as a jump from nothing.
		if (component.PrevPosePool.Count != poolSize)
		{
			component.PrevPosePool.Resize(poolSize);
			if (poolSize > 0)
				Internal.MemCpy(component.PrevPosePool.Ptr, component.PosePool.Ptr,
					poolSize * sizeof(Float4x4));
		}

		if (component.Targets.IsEmpty)
		{
			Feed(sets, owner, component, poses);
			return;
		}

		// By id, to a live handle each frame, so a target created or respawned later is fed.
		for (let target in component.Targets)
			Feed(sets, mScene.FindEntity(target.Id), component, poses);
	}

	/// BORROWED for the frame: the component keeps the storage alive.
	private void Feed(InstancedMeshComponentManager sets, EntityHandle entity,
		InstancedSkinningComponent* component, uint32 poses)
	{
		// A target id that names no entity (deleted, or not spawned yet) feeds nothing.
		if (!mScene.IsValid(entity))
			return;
		let set = sets.Get(entity);
		if (set == null)
			return;

		set.PosePool = component.PosePool.Ptr;
		set.PrevPosePool = component.PrevPosePool.Ptr;
		set.PoseCount = poses;
		// A block per clip: the instance's clip picks it.
		set.PosesPerClip = component.PoseCount;
		set.BoneCount = component.BoneCount;
	}
}
