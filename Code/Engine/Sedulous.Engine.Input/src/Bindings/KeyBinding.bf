namespace Sedulous.Engine.Input;

using System;
using Sedulous.Shell.Input;

/// Binding for a keyboard key with optional modifier requirements.
class KeyBinding : InputBinding
{
	/// The key code to bind.
	public KeyCode Key = .Unknown;

	/// Required modifiers (e.g., Ctrl+S requires .Ctrl).
	public KeyModifiers RequiredModifiers = .None;

	public this()
	{
	}

	public this(KeyCode key, KeyModifiers modifiers = .None)
	{
		Key = key;
		RequiredModifiers = modifiers;
		UpdateDisplayName();
	}

	public override InputSource Source => .Keyboard;

	public override InputValue GetValue(IInputManager input)
	{
		if (!CheckModifiers(input.Keyboard))
			return .FromBool(false);
		return .FromBool(input.Keyboard.IsKeyDown(Key));
	}

	public override bool WasPressed(IInputManager input)
	{
		if (!CheckModifiers(input.Keyboard))
			return false;
		return input.Keyboard.IsKeyPressed(Key);
	}

	public override bool WasReleased(IInputManager input)
	{
		return input.Keyboard.IsKeyReleased(Key);
	}

	private bool CheckModifiers(IKeyboard keyboard)
	{
		if (RequiredModifiers == .None)
			return true;
		return (keyboard.Modifiers & RequiredModifiers) == RequiredModifiers;
	}

	protected override void UpdateDisplayName()
	{
		DisplayName.Clear();
		if (RequiredModifiers.HasFlag(.Ctrl))
			DisplayName.Append("Ctrl+");
		if (RequiredModifiers.HasFlag(.Alt))
			DisplayName.Append("Alt+");
		if (RequiredModifiers.HasFlag(.Shift))
			DisplayName.Append("Shift+");
		Key.ToString(DisplayName);
	}

	public override InputBinding Clone()
	{
		return new KeyBinding(Key, RequiredModifiers);
	}
}
