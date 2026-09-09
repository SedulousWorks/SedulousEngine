using System;

namespace Sedulous.UI;

/// A keyboard shortcut: a key and modifiers bound to an action.
///
/// Ref counted so the manager can own them and still hand back stable references.
class Shortcut : RefCounted
{
	public KeyCode Key = .Unknown;
	public KeyModifiers Modifiers = .None;
	/// The text a menu shows. Empty means derive it.
	public String DisplayText = new .() ~ delete _;
	/// OWNED. Run when the shortcut fires.
	public delegate void() Action ~ delete _;
	/// BORROWED. Null is global, firing whatever has focus.
	public View Scope = null;
	public bool IsEnabled = true;

	public this() {}

	/// OWNERSHIP of the action transfers.
	public this(KeyCode key, KeyModifiers modifiers, delegate void() action, View scopeView = null)
	{
		Key = key;
		Modifiers = modifiers;
		Action = action;
		// Not named `scope`: that is a Beef keyword.
		Scope = scopeView;
	}

	/// Whether this matches a key event, with the left and right modifier variants treated
	/// alike: nobody binds a shortcut to the RIGHT control key specifically.
	public bool Matches(KeyCode key, KeyModifiers modifiers)
	{
		if (key != Key)
			return false;
		return Normalize(Modifiers) == Normalize(modifiers);
	}

	/// Collapses the sided modifiers into their combined flags and DROPS the lock keys, so
	/// that a shortcut still fires with caps lock or num lock on.
	private static KeyModifiers Normalize(KeyModifiers modifiers)
	{
		var result = modifiers;

		if (result.HasAny(.LeftShift) || result.HasAny(.RightShift))
			result |= .Shift;
		if (result.HasAny(.LeftCtrl) || result.HasAny(.RightCtrl))
			result |= .Ctrl;
		if (result.HasAny(.LeftAlt) || result.HasAny(.RightAlt))
			result |= .Alt;
		if (result.HasAny(.LeftGui) || result.HasAny(.RightGui))
			result |= .Gui;

		return result & (KeyModifiers.Ctrl | KeyModifiers.Shift | KeyModifiers.Alt
			| KeyModifiers.Gui);
	}
}
