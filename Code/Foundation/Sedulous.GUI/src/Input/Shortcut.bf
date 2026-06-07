namespace Sedulous.GUI;

using System;

/// A keyboard shortcut binding: key + modifiers -> action.
public class Shortcut
{
	/// The key that triggers this shortcut.
	public KeyCode Key;

	/// Required modifier keys (Ctrl, Shift, Alt, etc.).
	public KeyModifiers Modifiers;

	/// Display text for menus (e.g., "Ctrl+S"). Null = auto-generated.
	public String DisplayText ~ delete _;

	/// The action to execute when the shortcut fires.
	public delegate void() Action ~ delete _;

	/// Optional scope view - shortcut only fires when this view or a descendant
	/// has focus. Null = global shortcut (fires regardless of focus).
	public View Scope;

	/// Whether the shortcut is currently active.
	public bool IsEnabled = true;

	public this(KeyCode key, KeyModifiers modifiers, delegate void() action, View @scope = null)
	{
		Key = key;
		Modifiers = modifiers;
		Action = action;
		Scope = @scope;
	}

	/// Check if this shortcut matches the given key event.
	/// Normalizes Left/Right modifier variants so .Ctrl matches .LeftCtrl etc.
	public bool Matches(KeyCode key, KeyModifiers modifiers)
	{
		if (key != Key) return false;
		return Normalize(Modifiers) == Normalize(modifiers);
	}

	/// Collapse Left/Right modifier variants into combined flags,
	/// strip lock keys (CapsLock/NumLock/ScrollLock).
	private static KeyModifiers Normalize(KeyModifiers m)
	{
		var r = m;
		if (r.HasFlag(.LeftShift) || r.HasFlag(.RightShift))
			r |= .Shift;
		if (r.HasFlag(.LeftCtrl) || r.HasFlag(.RightCtrl))
			r |= .Ctrl;
		if (r.HasFlag(.LeftAlt) || r.HasFlag(.RightAlt))
			r |= .Alt;
		if (r.HasFlag(.LeftGui) || r.HasFlag(.RightGui))
			r |= .Gui;
		return r & (.Ctrl | .Shift | .Alt | .Gui);
	}
}
