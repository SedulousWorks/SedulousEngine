using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Script;

namespace Sedulous.Engine.Script.Facades;

/// `Input`: the run's actions, by name. Each run has its own action runtime, so the
/// application installs one of these per run, and instance A's script never sees B's keys.
[Scriptable, ServiceFacade("Input")]
class InputFacade
{
	/// BORROWED: the run's runtime.
	private ActionRuntime mRuntime;

	public this(ActionRuntime runtime)
	{
		mRuntime = runtime;
	}

	/// Held this frame.
	[Scriptable]
	public bool IsDown(StringView action) => (mRuntime != null) && mRuntime.IsDown(mRuntime.Resolve(action));
	/// Went down this frame.
	[Scriptable]
	public bool WasPressed(StringView action) => (mRuntime != null) && mRuntime.WasPressed(mRuntime.Resolve(action));
	[Scriptable]
	public bool WasReleased(StringView action) => (mRuntime != null) && mRuntime.WasReleased(mRuntime.Resolve(action));
	/// A one dimensional action's value, a trigger or a stick axis.
	[Scriptable]
	public float Value(StringView action) => (mRuntime != null) ? mRuntime.Value(mRuntime.Resolve(action)) : 0.0f;
	/// A two dimensional action's value, a stick or a d-pad.
	[Scriptable]
	public Float2 Value2D(StringView action) => (mRuntime != null) ? mRuntime.Value2D(mRuntime.Resolve(action)) : .Zero;

	/// Runs gamepad 0's motors for `seconds`: `low` the heavy, low frequency motor and `high` the
	/// light, high frequency one, each 0 to 1 (a crash 0.8, 0.4, 0.25; a footstep 0, 0.2, 0.05).
	/// It reaches the calling run's own pad (an editor Game tab's, the player's).
	[Scriptable]
	public void Rumble(float low, float high, float seconds) => Rumble(0, low, high, seconds);
	/// The same, for pad `gamepad` (0 first).
	[Scriptable]
	public void Rumble(int32 gamepad, float low, float high, float seconds) => mRuntime?.Rumble(gamepad, low, high, seconds);
	/// Stops every pad's rumble (a run's end stops it too).
	[Scriptable]
	public void StopRumble() => mRuntime?.StopRumble();
}
