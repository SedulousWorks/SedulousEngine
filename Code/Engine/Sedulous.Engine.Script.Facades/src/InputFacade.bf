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
}
