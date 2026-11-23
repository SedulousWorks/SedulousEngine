using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Input;

/// A game's controls as the player has them: the game's map with the player's overrides over it,
/// kept on an action runtime. The map stays as authored and the overrides (InputBindingOverrides)
/// lie over it, kept wherever the host saves them (a run's save file); a change reaches the
/// runtime at once without resetting the game's sets. A binding comes by name (ParseControl) or
/// as the player's next press (a capture), and replaces only the action's binding for that kind of
/// device: rebinding the keyboard keeps the pad's. Without a store the overrides live here, for
/// the run only.
class PlayerBindings
{
	/// BORROWED.
	private ActionRuntime mRuntime = null;
	/// The game's own, as authored.
	private InputMap mMap = new .() ~ delete _;
	private bool mInstalled = false;
	/// BORROWED; null: mOwn.
	private InputBindingOverrides mStore = null;
	private InputBindingOverrides mOwn = new .() ~ delete _;
	private delegate void() mChanged ~ delete _;
	private bool mCapturing = false;
	/// A capture ended this frame: the runtime rests until the next Poll.
	private bool mResting = false;
	private InputKind mCaptureKind = .Keyboard;
	private String mCaptureSet = new .() ~ delete _;
	private String mCaptureAction = new .() ~ delete _;

	/// A control by name, as a binding: "Key.Space", "Mouse.Left", "Pad.South",
	/// "PadAxis.RightTrigger", each name as the shell's enum spells it, in any case. False when
	/// the device or the name is unknown.
	public static bool ParseControl(StringView text, out Binding outBinding)
	{
		outBinding = .();
		let dot = text.IndexOf('.');
		if (dot < 0)
			return false;
		let device = text.Substring(0, dot);
		let name = text.Substring(dot + 1);
		if (SameName(device, "Key"))
		{
			if (!ScriptedInputSource.ParseKey(name, let key))
				return false;
			outBinding.Source = .Key;
			outBinding.Code = (uint32)key;
		}
		else if (SameName(device, "Mouse"))
		{
			if (!ScriptedInputSource.ParseMouseButton(name, let button))
				return false;
			outBinding.Source = .MouseButton;
			outBinding.Code = (uint32)button;
		}
		else if (SameName(device, "Pad"))
		{
			if (!ScriptedInputSource.ParsePadButton(name, let button))
				return false;
			outBinding.Source = .GamepadButton;
			outBinding.Code = (uint32)button;
		}
		else if (SameName(device, "PadAxis"))
		{
			if (!ScriptedInputSource.ParsePadAxis(name, let axis))
				return false;
			outBinding.Source = .GamepadAxis;
			outBinding.Code = (uint32)axis;
		}
		else
			return false;
		return true;
	}

	/// `current` with `replacement` in place of its first binding of the same kind (the keyboard
	/// and the mouse are one kind, the pad another, touch a third), the rest of that kind dropped;
	/// after the others when it has none of that kind. Appended to `outBindings`.
	public static void WithBindingOfKind(Span<Binding> current, Binding replacement, List<Binding> outBindings)
	{
		let kind = ShownBinding.KindOf(replacement);
		bool placed = false;
		for (let binding in current)
		{
			if (ShownBinding.KindOf(binding) != kind)
			{
				outBindings.Add(binding);
				continue;
			}
			if (!placed)
			{
				outBindings.Add(replacement);
				placed = true;
			}
		}
		if (!placed)
			outBindings.Add(replacement);
	}

	/// Where the overrides are kept (BORROWED), and what to call when they change (OWNED). Null:
	/// kept here.
	public void SetStore(InputBindingOverrides store, delegate void() changed)
	{
		mStore = store;
		delete mChanged;
		mChanged = changed;
	}

	/// Installs `map` on `runtime` with the overrides over it; `runtime` is remembered.
	public void Install(ActionRuntime runtime, InputMap map)
	{
		mRuntime = runtime;
		map.CopyTo(mMap);
		mInstalled = true;
		let effective = scope InputMap();
		map.CopyTo(effective);
		Overrides.ApplyTo(effective);
		runtime.SetMap(effective);
	}

	/// Applies the overrides again over the game's bindings, action by action, keeping the
	/// runtime's sets as they are: after the store changed underneath (a save file opened).
	public void Reapply()
	{
		if ((mRuntime == null) || !mInstalled)
			return;
		let effective = scope InputMap();
		mMap.CopyTo(effective);
		Overrides.ApplyTo(effective);
		for (let set in effective.Sets)
		{
			for (let action in set.Actions)
				mRuntime.ReplaceBindings(set.Name, action.Name, action.Bindings);
		}
	}

	/// Binds `action` (in `set`; empty: the set it is read from) to `binding`, in place of its
	/// binding of the same kind. False when there is no such action, or it is two dimensional (one
	/// control cannot drive two axes).
	public bool Set(StringView set, StringView action, Binding binding)
	{
		if (mRuntime == null)
			return false;
		let setName = scope String(set.IsEmpty ? mRuntime.SetOf(action) : set);
		let current = mRuntime.FindAction(setName, action);
		if ((current == null) || (current.Kind == .Axis2D))
			return false;
		let bindings = scope List<Binding>();
		WithBindingOfKind(current.Bindings, binding, bindings);
		mRuntime.ReplaceBindings(setName, action, bindings);
		Overrides.Set(setName, action, bindings);
		Changed();
		return true;
	}

	/// Gives `action` (in `set`; empty: the set it is read from) the game's own bindings again.
	/// False when there is no such action.
	public bool Reset(StringView set, StringView action)
	{
		if (mRuntime == null)
			return false;
		let setName = scope String(set.IsEmpty ? mRuntime.SetOf(action) : set);
		let authored = FindIn(mMap, setName, action);
		if (authored == null)
			return false;
		mRuntime.ReplaceBindings(setName, action, authored.Bindings);
		Overrides.Clear(setName, action);
		Changed();
		return true;
	}

	/// Every action back to the game's own bindings.
	public void ResetAll()
	{
		if (Overrides.Overrides.IsEmpty)
			return;
		ClearAndDeleteItems!(Overrides.Overrides);
		Reapply();
		Changed();
	}

	/// Starts taking the player's next press on a device of `kind` as `action`'s binding (in
	/// `set`; empty: the set it is read from); every action reads released meanwhile. Escape, or
	/// the pad's Back, cancels. False, and nothing taken, when there is no such action or it is not
	/// a button.
	public bool BeginCapture(StringView set, StringView action, InputKind kind)
	{
		if (mRuntime == null)
			return false;
		let setName = scope String(set.IsEmpty ? mRuntime.SetOf(action) : set);
		let current = mRuntime.FindAction(setName, action);
		if ((current == null) || (current.Kind != .Button))
			return false;
		mCaptureSet.Set(setName);
		mCaptureAction.Set(action);
		mCaptureKind = (kind == .Pad) ? .Pad : .Keyboard;
		mCapturing = true;
		mRuntime.SetListening(true);
		return true;
	}

	public void CancelCapture()
	{
		if (!mCapturing && !mResting)
			return;
		mCapturing = false;
		mResting = false;
		if (mRuntime != null)
			mRuntime.SetListening(false);
	}

	public bool IsCapturing => mCapturing;

	/// Takes this frame's first press of the kind being captured, if any. Call before the
	/// runtime's update, every frame. The frame a capture ends in still rests, so the press that
	/// ended it is held through a rest and fires nothing until it is let go.
	public void Poll(IInputSourceProvider source)
	{
		if (mResting)
		{
			mResting = false;
			if (!mCapturing && (mRuntime != null))
				mRuntime.SetListening(false);
		}
		if (!mCapturing)
			return;
		let keyboard = source.Keyboard;
		let mouse = source.Mouse;
		for (let input in source.Events)
		{
			bool taken = false;
			bool cancel = false;
			var binding = Binding();
			if (mCaptureKind == .Keyboard)
			{
				// A key's edge only: a held key repeats its KeyDown.
				if ((input.Kind == .KeyDown) && (keyboard != null) && keyboard.IsKeyPressed(input.Key))
				{
					if (input.Key == .Escape)
						cancel = true;
					else
					{
						binding.Source = .Key;
						binding.Code = (uint32)input.Key;
						taken = true;
					}
				}
				else if ((input.Kind == .MouseButtonDown) && (mouse != null) && mouse.IsButtonPressed(input.Button))
				{
					binding.Source = .MouseButton;
					binding.Code = (uint32)input.Button;
					taken = true;
				}
			}
			else if (input.Kind == .GamepadButtonDown)
			{
				if (input.PadButton == .Back)
					cancel = true;
				else
				{
					binding.Source = .GamepadButton;
					binding.Code = (uint32)input.PadButton;
					taken = true;
				}
			}
			else if ((input.Kind == .GamepadAxis) && (input.Value >= ActionRuntime.cPressPoint)
				&& ((input.PadAxis == .LeftTrigger) || (input.PadAxis == .RightTrigger)))
			{
				binding.Source = .GamepadAxis;
				binding.Code = (uint32)input.PadAxis;
				taken = true;
			}
			if (cancel || taken)
			{
				mCapturing = false;
				mResting = true; // listening ends at the next Poll
				if (taken)
					Set(mCaptureSet, mCaptureAction, binding);
				return;
			}
		}
	}

	/// The overrides now. BORROWED.
	public InputBindingOverrides Current => Overrides;

	private InputBindingOverrides Overrides => (mStore != null) ? mStore : mOwn;

	/// Whether `a` and `b` are the same name, ASCII case ignored.
	private static bool SameName(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (a[i].ToLower != b[i].ToLower)
				return false;
		}
		return true;
	}

	private void Changed()
	{
		if (mChanged != null)
			mChanged();
	}

	private static InputAction FindIn(InputMap map, StringView set, StringView action)
	{
		for (let candidate in map.Sets)
		{
			if (candidate.Name != set)
				continue;
			for (let a in candidate.Actions)
			{
				if (a.Name == action)
					return a;
			}
		}
		return null;
	}
}
