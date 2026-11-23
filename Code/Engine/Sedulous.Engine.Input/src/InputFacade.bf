using System;
using Sedulous.Core;
using Sedulous.Input;
using Sedulous.Script;

namespace Sedulous.Engine.Input;

/// `Input`: the run's actions, by name. Each run has its own action runtime and its own one of
/// these among its services (a ApplicationRun's), so instance A's script never sees B's keys; the
/// subsystem offers an idle one, over no runtime, to scripts outside every run.
[Scriptable, ServiceFacade("Input")]
class InputFacade
{
	/// BORROWED: the run's runtime.
	private ActionRuntime mRuntime;
	/// BORROWED: the input subsystem's input kind, which Describe names the control for; null
	/// names the keyboard's.
	private InputKindTracker mInputKinds = null;
	/// What Describe hands back, until its next call.
	private String mDescribed = new .() ~ delete _;
	/// BORROWED: the run's player bindings, which the rebinding goes through; null outside a run.
	private PlayerBindings mBindings = null;

	public this(ActionRuntime runtime, PlayerBindings bindings = null)
	{
		mRuntime = runtime;
		mBindings = bindings;
	}

	/// The input kind Describe follows: the input subsystem points its own and each run's at its
	/// tracker, and clears them as it goes. BORROWED.
	public InputKindTracker InputKinds
	{
		get => mInputKinds;
		set => mInputKinds = value;
	}

	// ---- the player's rebinding, kept in the game's save ----

	/// Takes the player's next press on the device in hand (the keyboard and mouse, or a pad) as
	/// `action`'s binding for that device, in place of its old one; every action reads released
	/// until then. Escape, or the pad's Back, cancels. False when the action is not a button of the
	/// game's controls.
	[Scriptable]
	public bool Rebind(StringView action) => Rebind(action, "");
	/// The same, for the action in `set`.
	[Scriptable]
	public bool Rebind(StringView action, StringView set) =>
		(mBindings != null) && mBindings.BeginCapture(set, action, (mInputKinds != null) ? mInputKinds.Kind : .Keyboard);
	/// Whether a rebind is waiting for the player's press.
	[Scriptable]
	public bool IsRebinding() => (mBindings != null) && mBindings.IsCapturing;
	/// Stops waiting; the action keeps its binding.
	[Scriptable]
	public void CancelRebind() => mBindings?.CancelCapture();
	/// Binds `action` to a control by name ("Key.Space", "Mouse.Left", "Pad.South",
	/// "PadAxis.RightTrigger"), in place of its binding for that device. False for an unknown
	/// control or action, or a two dimensional action.
	[Scriptable]
	public bool SetBinding(StringView action, StringView control) => SetBinding(action, control, "");
	/// The same, for the action in `set`.
	[Scriptable]
	public bool SetBinding(StringView action, StringView control, StringView set)
	{
		if (mBindings == null)
			return false;
		Binding binding;
		if (!PlayerBindings.ParseControl(control, out binding))
			return false;
		return mBindings.Set(set, action, binding);
	}
	/// Gives `action` the game's own bindings again. False for an unknown action.
	[Scriptable]
	public bool ResetBinding(StringView action) => ResetBinding(action, "");
	/// The same, for the action in `set`.
	[Scriptable]
	public bool ResetBinding(StringView action, StringView set) => (mBindings != null) && mBindings.Reset(set, action);
	/// Every action back to the game's own bindings.
	[Scriptable]
	public void ResetAllBindings() => mBindings?.ResetAll();

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

	/// Locks the pointer for mouse look (hidden, held in place, only its movement read: bind
	/// MouseDelta to a look action), or frees it with false. A browser grants a lock only on a
	/// click, so on the web it takes effect at the player's next click in the game. A run's end
	/// frees it.
	[Scriptable]
	public void LockPointer(bool locked) => mRuntime?.SetPointerLock(locked);
	/// Whether the pointer is locked: asked and granted. False after a browser's Escape freed it
	/// (a game shows its pause then).
	[Scriptable]
	public bool PointerLocked() => (mRuntime != null) && mRuntime.PointerLocked;

	/// What the player presses for `action` on the device in hand ("Space", "Pad South"): the
	/// control a GUI prompt for it shows, for a sentence that names it. Read from the
	/// highest-priority enabled set with the action, after the player's rebinding; "" when it has
	/// no binding (or there is no runtime).
	[Scriptable]
	public StringView Describe(StringView action) => Describe(action, "");
	/// The same, for the action in `set`, enabled or not.
	[Scriptable]
	public StringView Describe(StringView action, StringView set)
	{
		mDescribed.Clear();
		let kind = (mInputKinds != null) ? mInputKinds.Kind : InputKind.Pointer;
		let binding = ShownBinding.For(mRuntime, action, set, kind);
		if (binding.HasValue)
			BindingNames.DescribeBinding(binding.Value, mDescribed);
		return mDescribed;
	}

	// ---- action sets: a menu over gameplay ----

	/// Makes the set `name` modal: while it is on top only its actions read, so a "Menu" set
	/// silences gameplay under a menu. What is held across the change needs a fresh press, so
	/// a held Jump neither confirms the menu that opened nor fires as it closes.
	[Scriptable]
	public void PushSet(StringView name) => mRuntime?.PushExclusiveSet(name);
	/// The last pushed set comes off; the one under it, or every enabled set, reads again.
	[Scriptable]
	public void PopSet() => mRuntime?.PopExclusiveSet();
	/// Turns a set's actions on or off, outside the modal stack.
	[Scriptable]
	public void EnableSet(StringView name, bool enabled) => mRuntime?.EnableSet(name, enabled);
}
