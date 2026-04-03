namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Handle to an animation instance.
public struct AnimatedMeshHandle : IHashable
{
	public uint64 Id;

	public bool IsValid => Id != 0;

	public int GetHashCode() => Id.GetHashCode();

	public static bool operator==(Self a, Self b) => a.Id == b.Id;
	public static bool operator!=(Self a, Self b) => a.Id != b.Id;
}

/// Manages animation playback for multiple skinned mesh instances.
public class AnimationSystem
{
	/// All active animation instances.
	private Dictionary<AnimatedMeshHandle, AnimationInstance> mInstances = new .() ~ {
		for (let kv in _)
			delete kv.value;
		delete _;
	};

	/// Next instance ID for handle generation.
	private uint64 mNextInstanceId = 1;

	/// Creates a new animated instance for a skeleton.
	/// @param skeleton The skeleton to animate.
	/// @returns Handle to the animation instance.
	public AnimatedMeshHandle CreateInstance(Skeleton skeleton)
	{
		let handle = AnimatedMeshHandle() { Id = mNextInstanceId++ };
		let instance = new AnimationInstance(skeleton);
		mInstances[handle] = instance;
		return handle;
	}

	/// Destroys an animation instance.
	public void DestroyInstance(AnimatedMeshHandle handle)
	{
		if (mInstances.GetAndRemove(handle) case .Ok(let kv))
			delete kv.value;
	}

	/// Gets the animation player for an instance.
	public AnimationPlayer GetPlayer(AnimatedMeshHandle handle)
	{
		if (mInstances.TryGetValue(handle, let instance))
			return instance.Player;
		return null;
	}

	/// Plays an animation on an instance.
	public void Play(AnimatedMeshHandle handle, AnimationClip clip, bool restart = true)
	{
		if (mInstances.TryGetValue(handle, let instance))
			instance.Player.Play(clip, restart);
	}

	/// Stops an animation on an instance.
	public void Stop(AnimatedMeshHandle handle)
	{
		if (mInstances.TryGetValue(handle, let instance))
			instance.Player.Stop();
	}

	/// Updates all animation instances.
	/// @param deltaTime Time elapsed since last update in seconds.
	public void Update(float deltaTime)
	{
		for (let kv in mInstances)
		{
			let instance = kv.value;
			instance.Player.Update(deltaTime);
			instance.Player.Evaluate();
		}
	}

	/// Iterates over all instances, calling the provided delegate with each handle and player.
	/// Use this to upload bone matrices to the render system.
	public void ForEachInstance(delegate void(AnimatedMeshHandle handle, AnimationPlayer player) action)
	{
		for (let kv in mInstances)
		{
			action(kv.key, kv.value.Player);
		}
	}

	/// Internal animation instance data.
	private class AnimationInstance
	{
		public AnimationPlayer Player ~ delete _;

		public this(Skeleton skeleton)
		{
			Player = new AnimationPlayer(skeleton);
		}
	}
}
