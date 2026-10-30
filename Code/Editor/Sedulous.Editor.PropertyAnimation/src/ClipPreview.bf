using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;

namespace Sedulous.Editor.PropertyAnimation;

/// A clip previewed on an entity of a scene: what Add Track offers on it, its targets read, and the
/// entity posed by the clip at a time, what it held first kept and put back when the preview ends.
/// Nothing it writes is anyone's step or unsaved edit: the writes are transient.
class ClipPreview
{
	/// The entity's own transform, animated by this name (it is the scene's, not a component).
	public const String cTransformName = "Transform";

	/// Borrowed: the scene outlives it.
	private Sedulous.Scene.Scene mScene;
	private bool mPosing = false;
	private Guid mEntity = .Empty;
	/// Each target as it was before the preview.
	private List<PreviewSnapshotEntry> mKept = new .() ~ DeleteContainerAndItems!(_);
	/// The tracks it was kept for ("component|path" each).
	private List<String> mTracks = new .() ~ DeleteContainerAndItems!(_);

	public this(Sedulous.Scene.Scene scene)
	{
		mScene = scene;
	}

	public ~this()
	{
		Stop();
	}

	public bool IsPosing => mPosing;
	public Guid PosedEntity => mEntity;

	/// What Add Track offers on `entity`: its transform's, then each component's; appended (the list
	/// owns them).
	public void TrackSeeds(Guid entity, List<AnimatablePropertyInfo> outSeeds)
	{
		let handle = mScene.FindEntity(entity);
		if (!handle.IsAssigned)
			return;
		// Every entity has a transform (the scene's, not a reflected component): its TRS first.
		outSeeds.Add(new AnimatablePropertyInfo(cTransformName, "Position", .Float3));
		outSeeds.Add(new AnimatablePropertyInfo(cTransformName, "Rotation", .Quat));
		outSeeds.Add(new AnimatablePropertyInfo(cTransformName, "Scale", .Float3));
		mScene.ForEachManager(scope [&] (manager) =>
			{
				if (manager.HasComponent(handle) && (manager.ComponentType != null))
					AnimatableProperties.Collect(manager.ComponentType, outSeeds);
			});
	}

	/// A track target's value on `entity` now (empty: no such entity, component or property).
	public PropertyValue Read(Guid entity, StringView componentType, StringView propertyPath)
	{
		let handle = mScene.FindEntity(entity);
		return handle.IsAssigned ? ReadTarget(handle, componentType, propertyPath) : .Empty;
	}

	/// `entity` posed by `clip` at `time` (what it held first kept, to be put back).
	public void Pose(Guid entity, PropertyAnimationClip clip, float time)
	{
		let handle = mScene.FindEntity(entity);
		if (!handle.IsAssigned)
		{
			Stop();
			return;
		}
		// Kept again when the entity or the tracks changed: what was kept may name targets gone.
		let tracks = scope List<String>();
		defer { ClearAndDeleteItems!(tracks); }
		for (let track in clip.Tracks)
			tracks.Add(new $"{track.ComponentType}|{track.PropertyPath}");
		var same = mPosing && (mEntity == entity) && (tracks.Count == mTracks.Count);
		for (int i = 0; same && (i < tracks.Count); i++)
			same = tracks[i] == mTracks[i];
		if (!same)
		{
			Stop();
			for (let track in clip.Tracks)
			{
				let value = ReadTarget(handle, track.ComponentType, track.PropertyPath);
				if (!value.HasValue)
					continue;
				let kept = new PreviewSnapshotEntry();
				kept.ComponentType.Set(track.ComponentType);
				kept.PropertyPath.Set(track.PropertyPath);
				kept.Value = value;
				mKept.Add(kept);
			}
			for (let track in tracks)
				mTracks.Add(new String(track));
			mEntity = entity;
			mPosing = true;
		}
		for (let track in clip.Tracks)
		{
			// A channel with no keys keeps what the entity has (an X-only track leaves Y and Z be).
			let current = ReadTarget(handle, track.ComponentType, track.PropertyPath);
			WriteTarget(handle, track.ComponentType, track.PropertyPath, track.SampleMerged(time, current));
		}
	}

	/// What the preview wrote put back; it ends.
	public void Stop()
	{
		if (!mPosing)
			return;
		let handle = mScene.FindEntity(mEntity);
		if (handle.IsAssigned)
		{
			for (let kept in mKept)
				WriteTarget(handle, kept.ComponentType, kept.PropertyPath, kept.Value);
		}
		ClearAndDeleteItems!(mKept);
		ClearAndDeleteItems!(mTracks);
		mEntity = .Empty;
		mPosing = false;
	}

	private ComponentManagerBase ManagerNamed(StringView name)
	{
		ComponentManagerBase found = null;
		let typeName = scope String();
		mScene.ForEachManager(scope [&] (manager) =>
			{
				if ((found != null) || (manager.ComponentType == null))
					return;
				typeName.Clear();
				manager.ComponentType.GetName(typeName);
				if (typeName == name)
					found = manager;
			});
		return found;
	}

	private PropertyValue ReadTarget(EntityHandle entity, StringView componentType, StringView propertyPath)
	{
		let binding = scope PropertyBinding();
		if (componentType == cTransformName)
		{
			PropertyBindingResolver.Resolve(typeof(Transform), propertyPath, binding);
			if (!binding.IsResolved)
				return .Empty;
			var local = mScene.GetLocalTransform(entity);
			return PropertyBindingResolver.Read(binding, &local, typeof(Transform));
		}
		let manager = ManagerNamed(componentType);
		if ((manager == null) || !manager.HasComponent(entity))
			return .Empty;
		PropertyBindingResolver.Resolve(manager.ComponentType, propertyPath, binding);
		if (!binding.IsResolved)
			return .Empty;
		return PropertyBindingResolver.Read(binding, manager.GetComponentAddress(entity), manager.ComponentType);
	}

	private void WriteTarget(EntityHandle entity, StringView componentType, StringView propertyPath, PropertyValue value)
	{
		let binding = scope PropertyBinding();
		if (componentType == cTransformName)
		{
			PropertyBindingResolver.Resolve(typeof(Transform), propertyPath, binding);
			if (!binding.IsResolved)
				return;
			// Through SetLocalTransform, so the world matrix follows.
			var local = mScene.GetLocalTransform(entity);
			if (PropertyBindingResolver.Write(binding, &local, typeof(Transform), value) case .Ok)
				mScene.SetLocalTransform(entity, local);
			return;
		}
		let manager = ManagerNamed(componentType);
		if ((manager == null) || !manager.HasComponent(entity))
			return;
		PropertyBindingResolver.Resolve(manager.ComponentType, propertyPath, binding);
		if (binding.IsResolved)
			PropertyBindingResolver.Write(binding, manager.GetComponentAddress(entity), manager.ComponentType, value).IgnoreError();
	}
}

/// The transport's clock over a clip's length.
class ClipTransport
{
	private float mTime = 0.0f;
	private bool mPlaying = false;
	private bool mPaused = false;
	/// As a new animator loops.
	private bool mLooping = true;

	public float Time => mTime;
	public bool IsPlaying => mPlaying && !mPaused;
	public bool IsPaused => mPlaying && mPaused;
	public bool IsLooping => mLooping;

	/// From where it stands (from the start when it stands at the end).
	public void Play(float length)
	{
		if (mTime >= length - 1e-4f)
			mTime = 0.0f;
		mPlaying = true;
		mPaused = false;
	}

	public void Pause()
	{
		if (mPlaying)
			mPaused = true;
	}

	/// Stopped, back at the start.
	public void Stop()
	{
		mPlaying = false;
		mPaused = false;
		mTime = 0.0f;
	}

	/// A scrub: the time set where it is shown, playing or not.
	public void SetTime(float time) { mTime = Math.Max(0.0f, time); }

	public void SetLooping(bool looping) { mLooping = looping; }

	/// Moves on by `dt` while playing; true when the time moved. At the end it wraps when looping,
	/// else stops there.
	public bool Advance(float dt, float length)
	{
		if (!mPlaying || mPaused || (dt <= 0.0f))
			return false;
		let span = Math.Max(length, 1e-3f);
		mTime += dt;
		if (mTime >= span)
		{
			if (mLooping)
			{
				while (mTime >= span)
					mTime -= span;
			}
			else
			{
				mTime = span;
				mPlaying = false;
			}
		}
		return true;
	}
}
