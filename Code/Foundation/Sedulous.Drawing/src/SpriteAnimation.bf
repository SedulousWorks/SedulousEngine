using System;
using System.Collections;

namespace Sedulous.Drawing;

/// A frame in a sprite animation
public struct AnimationFrame
{
	/// The sprite for this frame
	public Sprite Sprite;
	/// Duration of this frame in seconds
	public float Duration;

	public this(Sprite sprite, float duration)
	{
		Sprite = sprite;
		Duration = duration;
	}
}

/// An animation consisting of multiple sprite frames
public class SpriteAnimation
{
	private List<AnimationFrame> mFrames = new .() ~ delete _;
	private bool mLooping = true;
	private String mName ~ delete _;

	/// Animation name
	public StringView Name => mName;

	/// Whether the animation loops
	public bool Looping
	{
		get => mLooping;
		set => mLooping = value;
	}

	/// Number of frames in the animation
	public int FrameCount => mFrames.Count;

	/// Total duration of the animation in seconds
	public float TotalDuration
	{
		get
		{
			float total = 0;
			for (let frame in mFrames)
				total += frame.Duration;
			return total;
		}
	}

	public this(StringView name)
	{
		mName = new String(name);
	}

	/// Add a frame to the animation
	public void AddFrame(Sprite sprite, float duration)
	{
		mFrames.Add(.(sprite, duration));
	}

	/// Add multiple frames with the same duration
	public void AddFrames(Span<Sprite> sprites, float durationPerFrame)
	{
		for (let sprite in sprites)
		{
			mFrames.Add(.(sprite, durationPerFrame));
		}
	}

	/// Get the frame at a specific index
	public AnimationFrame GetFrame(int index)
	{
		if (index < 0 || index >= mFrames.Count)
			return default;
		return mFrames[index];
	}

	/// Get the sprite at a given time
	public Sprite GetSpriteAtTime(float time)
	{
		if (mFrames.Count == 0)
			return default;

		let totalDuration = TotalDuration;
		if (totalDuration <= 0)
			return mFrames[0].Sprite;

		// Handle looping
		var t = time;
		if (mLooping)
		{
			t = time % totalDuration;
		}
		else if (time >= totalDuration)
		{
			return mFrames[mFrames.Count - 1].Sprite;
		}

		// Find the current frame
		float elapsed = 0;
		for (let frame in mFrames)
		{
			elapsed += frame.Duration;
			if (t < elapsed)
				return frame.Sprite;
		}

		return mFrames[mFrames.Count - 1].Sprite;
	}

	/// Get the frame index at a given time
	public int GetFrameIndexAtTime(float time)
	{
		if (mFrames.Count == 0)
			return 0;

		let totalDuration = TotalDuration;
		if (totalDuration <= 0)
			return 0;

		// Handle looping
		var t = time;
		if (mLooping)
		{
			t = time % totalDuration;
		}
		else if (time >= totalDuration)
		{
			return mFrames.Count - 1;
		}

		// Find the current frame
		float elapsed = 0;
		for (int i = 0; i < mFrames.Count; i++)
		{
			elapsed += mFrames[i].Duration;
			if (t < elapsed)
				return i;
		}

		return mFrames.Count - 1;
	}

	/// Clear all frames
	public void Clear()
	{
		mFrames.Clear();
	}

	/// Create an animation from a sprite sheet grid
	public static SpriteAnimation FromGrid(SpriteSheet sheet, StringView baseName, int frameCount, float durationPerFrame, StringView animName)
	{
		let anim = new SpriteAnimation(animName);
		for (int i = 0; i < frameCount; i++)
		{
			let spriteName = scope String();
			spriteName.AppendF("{}_{}", baseName, i);
			if (let sprite = sheet.GetSprite(spriteName))
			{
				anim.AddFrame(sprite, durationPerFrame);
			}
		}
		return anim;
	}
}

/// Tracks playback state for a sprite animation
public struct AnimationPlayer
{
	/// Current time in seconds
	public float CurrentTime;
	/// Whether the animation is playing
	public bool IsPlaying;
	/// Playback speed multiplier (1.0 = normal speed)
	public float Speed;

	public this()
	{
		CurrentTime = 0;
		IsPlaying = false;
		Speed = 1.0f;
	}

	/// Start playing
	public void Play() mut
	{
		IsPlaying = true;
	}

	/// Pause playback
	public void Pause() mut
	{
		IsPlaying = false;
	}

	/// Stop and reset to beginning
	public void Stop() mut
	{
		IsPlaying = false;
		CurrentTime = 0;
	}

	/// Reset to beginning without stopping
	public void Reset() mut
	{
		CurrentTime = 0;
	}

	/// Update the animation time
	public void Update(float deltaTime) mut
	{
		if (IsPlaying)
		{
			CurrentTime += deltaTime * Speed;
		}
	}

	/// Get the current sprite from an animation
	public Sprite GetCurrentSprite(SpriteAnimation animation)
	{
		return animation.GetSpriteAtTime(CurrentTime);
	}

	/// Get the current frame index from an animation
	public int GetCurrentFrameIndex(SpriteAnimation animation)
	{
		return animation.GetFrameIndexAtTime(CurrentTime);
	}
}
