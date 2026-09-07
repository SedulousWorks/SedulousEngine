using System;

namespace Sedulous.Shell;

/// The surface's view of one gamepad, gated by focus.
///
/// Gated the same way as the keyboard, and for the same reason: a pad drives whichever
/// viewport has focus rather than all of them at once. Rumble is NOT gated, since asking
/// an unfocused pad to stop rumbling has to work.
class SurfaceGamepad : IGamepad
{
	private InputSurface mSurface;
	private int32 mIndex;

	public void Bind(InputSurface surface, int32 index)
	{
		mSurface = surface;
		mIndex = index;
	}

	/// The raw device this stands for, or null when there is none at this index.
	public IGamepad RawDevice => (mSurface != null) ? mSurface.Raw.GetGamepad(mIndex) : null;

	public int32 Index => mIndex;

	public StringView Name
	{
		get
		{
			let raw = RawDevice;
			return (raw != null) ? raw.Name : default;
		}
	}

	public bool Connected
	{
		get
		{
			let raw = RawDevice;
			return (raw != null) && raw.Connected;
		}
	}

	public bool IsButtonDown(GamepadButton button)
	{
		let raw = RawDevice;
		return mSurface.Focused && (raw != null) && raw.IsButtonDown(button);
	}

	public bool IsButtonPressed(GamepadButton button)
	{
		let raw = RawDevice;
		return mSurface.Focused && (raw != null) && raw.IsButtonPressed(button);
	}

	public bool IsButtonReleased(GamepadButton button)
	{
		let raw = RawDevice;
		return mSurface.Focused && (raw != null) && raw.IsButtonReleased(button);
	}

	public float Axis(GamepadAxis axis)
	{
		let raw = RawDevice;
		return (mSurface.Focused && (raw != null)) ? raw.Axis(axis) : 0.0f;
	}

	public void SetRumble(float lowFrequency, float highFrequency, uint32 durationMs)
	{
		let raw = RawDevice;
		if (raw != null)
			raw.SetRumble(lowFrequency, highFrequency, durationMs);
	}
}
