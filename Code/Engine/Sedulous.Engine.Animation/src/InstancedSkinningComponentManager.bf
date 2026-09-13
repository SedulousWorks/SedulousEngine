using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Profiler;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Ticks every crowd in the animation phase, before extraction: advance the shared clock,
/// sample the clip at each phase into the pose pool, and hand the pool to the target sets.
class InstancedSkinningComponentManager : ComponentManager<InstancedSkinningComponent>
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
		component.Targets = new List<EntityHandle>();
		component.PosePool = new List<Float4x4>();
		component.PrevPosePool = new List<Float4x4>();
		component.Scratch = new List<BoneTransform>();
	}

	protected override void OnComponentDestroyed(InstancedSkinningComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.Targets);
		DeleteAndNullify!(component.PosePool);
		DeleteAndNullify!(component.PrevPosePool);
		DeleteAndNullify!(component.Scratch);
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

		if ((component.Skeleton == null) || (component.Clip == null) || (component.PoseCount == 0))
			return;

		let boneCount = (uint32)component.Skeleton.BoneCount;
		if (boneCount == 0)
			return;

		component.BoneCount = boneCount;
		let poolSize = (int)component.PoseCount * (int)boneCount;

		// Ping pong: last frame's pool becomes this frame's PREVIOUS, which is what the per
		// bone motion vectors read. Nothing is resampled for it.
		let swap = component.PosePool;
		component.PosePool = component.PrevPosePool;
		component.PrevPosePool = swap;

		component.PosePool.Resize(poolSize);
		component.Scratch.Resize(boneCount);

		let duration = (component.Clip.Duration > 0.0f) ? component.Clip.Duration : 1.0f;
		component.Time += deltaTime * component.Speed;
		while (component.Time >= duration)
			component.Time -= duration;
		while (component.Time < 0.0f)
			component.Time += duration;

		// One palette per phase, evenly spaced, so the whole crowd cycles through the clip
		// together rather than each instance keeping its own clock.
		let scratch = Span<BoneTransform>(component.Scratch.Ptr, component.Scratch.Count);
		for (uint32 index < component.PoseCount)
		{
			var phase = component.Time
				+ ((float)index / (float)component.PoseCount) * duration;
			while (phase >= duration)
				phase -= duration;

			AnimationSampler.SampleClip(component.Clip, component.Skeleton, phase, scratch);
			component.Skeleton.ComputeSkinningMatrices(scratch,
				.(component.PosePool.Ptr + (int)index * (int)boneCount, boneCount));
		}

		// The first frame, or a change of pose count: there is no previous pool, so it becomes
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
			Feed(sets, owner, component);
			return;
		}

		for (let target in component.Targets)
			Feed(sets, target, component);
	}

	/// BORROWED for the frame: the component keeps the storage alive.
	private void Feed(InstancedMeshComponentManager sets, EntityHandle entity,
		InstancedSkinningComponent* component)
	{
		let set = sets.Get(entity);
		if (set == null)
			return;

		set.PosePool = component.PosePool.Ptr;
		set.PrevPosePool = component.PrevPosePool.Ptr;
		set.PoseCount = component.PoseCount;
		set.BoneCount = component.BoneCount;
	}
}
