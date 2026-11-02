using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Animation;
using Sedulous.Model.Resource;
using Sedulous.Engine.Animation;

namespace Sedulous.Editor.ModelPreview;

// The animation bar's state, kept apart from the window (the import window's model preview).
// ModelInstances.Instantiate puts a skeletal animation component on the root of the model it
// places, and ClipPlayback drives that component: which of the model's clips plays, play and pause,
// stop (rewind and pause), stepping a frame while paused, scrubbing to a time, looping and speed.
// The component's manager builds the player on its first tick and starts the clip it was handed, so
// selecting a clip takes effect on the next scene update; the other controls act on the player at
// once.

class ClipPlayback
{
	/// The frame rate Step moves by: the rate the importer samples clips at.
	public const float cStepFps = 30.0f;

	/// BORROWED: the scene and the model outlive this.
	private Scene mScene;
	private EntityHandle mRoot;
	private ModelResource mModel;
	private int32 mSelected = -1;
	private bool mLooping = true;

	/// Drives the animator on `root` (the entity Instantiate made), playing the clips of `model`.
	/// When there is no animator (the model has no clips, or the scene has no animation managers)
	/// there is nothing to drive, and HasClips is false.
	public this(Scene scene, EntityHandle root, ModelResource model)
	{
		mScene = scene;
		mRoot = root;
		mModel = model;
		let animator = Animator;
		if (animator != null)
		{
			let playing = animator.Clip.Get;
			for (int i < mModel.Animations.Count)
			{
				if ((playing != null) && (mModel.Animations[i].Get === playing))
					mSelected = (int32)i;
			}
		}
		if (let clip = Clip(mSelected))
			clip.IsLooping = mLooping; // the preview loops clips whatever the file says
	}

	public bool HasClips => (Animator != null) && !mModel.Animations.IsEmpty;
	public int32 ClipCount => (int32)mModel.Animations.Count;
	public int32 Selected => mSelected;

	/// The clip's name as the cook made it, without the model prefix ("model."), appended.
	public void ClipName(int32 index, String outName)
	{
		let clip = Clip(index);
		if (clip == null)
			return;
		let name = clip.Name;
		let dot = name.IndexOf('.');
		outName.Append((dot >= 0) ? name.Substring(dot + 1) : name);
	}

	/// Plays clip `index` from its start, beginning on the next scene update.
	public void Select(int32 index)
	{
		let animator = Animator;
		let clip = Clip(index);
		if ((animator == null) || (clip == null))
			return;
		mSelected = index;
		clip.IsLooping = mLooping;
		animator.Clip.SetDirect(clip);
		animator.AutoPlay = true;
		animator.StartTime = 0.0f;
	}

	public bool Playing
	{
		get
		{
			let player = Player;
			return (player != null) && (player.State == .Playing);
		}
	}

	/// Plays from the current time, or pauses. A clip that does not loop and has reached its end
	/// starts again from the beginning.
	public void SetPlaying(bool playing)
	{
		let player = Player;
		if (player == null)
			return;
		if (!playing)
		{
			player.Pause();
			return;
		}
		if (player.State == .Paused)
			player.Resume();
		else if ((player.State == .Stopped) && (player.CurrentClip != null))
			player.Play(player.CurrentClip, Time >= Duration); // restart at the end
	}

	/// Rewinds to the clip's start and pauses.
	public void Stop()
	{
		let player = Player;
		if (player == null)
			return;
		player.Pause();
		player.SetCurrentTime(0.0f);
	}

	/// Moves `frames` frames forward (backward when negative) and pauses there.
	public void Step(int32 frames)
	{
		if (Player == null)
			return;
		SetPlaying(false);
		Scrub(Time + (float)frames / cStepFps);
	}

	/// Jumps to `seconds` into the clip, clamped to its length. If the clip was playing it continues
	/// from there.
	public void Scrub(float seconds)
	{
		let player = Player;
		if (player == null)
			return;
		player.SetCurrentTime(Math.Clamp(seconds, 0.0f, Duration));
	}

	public float Time
	{
		get
		{
			let player = Player;
			return (player != null) ? player.CurrentTime : 0.0f;
		}
	}

	public float Duration
	{
		get
		{
			let player = Player;
			let clip = ((player != null) && (player.CurrentClip != null)) ? player.CurrentClip : Clip(mSelected);
			return (clip != null) ? clip.Duration : 0.0f;
		}
	}

	public bool Looping => mLooping;

	/// Whether the clip starts over at its end, rather than stopping there. This changes the
	/// preview's copy of the clip; the file is untouched.
	public void SetLooping(bool looping)
	{
		mLooping = looping;
		if (let clip = Clip(mSelected))
			clip.IsLooping = looping;
	}

	public float Speed
	{
		get
		{
			let animator = Animator;
			return (animator != null) ? animator.Speed : 1.0f;
		}
	}

	public void SetSpeed(float speed)
	{
		let animator = Animator;
		if (animator != null)
			animator.Speed = speed;
	}

	/// The player, or null until the animator's manager builds it on its first tick.
	public AnimationPlayer Player
	{
		get
		{
			let animator = Animator;
			return (animator != null) ? animator.Player : null;
		}
	}

	private SkeletalAnimationComponent* Animator
	{
		get
		{
			let animators = mScene.GetSystem<SkeletalAnimationComponentManager>();
			return ((animators != null) && mScene.IsValid(mRoot)) ? animators.Get(mRoot) : null;
		}
	}

	private AnimationClip Clip(int32 index)
		=> ((index >= 0) && (index < mModel.Animations.Count)) ? mModel.Animations[index].Get : null;
}
