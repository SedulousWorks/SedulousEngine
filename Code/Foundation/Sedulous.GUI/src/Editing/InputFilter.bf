using System;

namespace Sedulous.GUI;

// What a text field lets in, one character at a time: everything, digits, hex digits, or a
// predicate of its own. Typed and pasted text both pass through it.
//
// Copied from foundation.ui's input filter, and the GUI's own from then on. It owns its predicate,
// so it is a class; whoever is handed one (a text edit model) owns it.

enum InputFilterMode
{
	None,
	Digits,
	HexDigits,
	Custom
}

class InputFilter
{
	private InputFilterMode mMode = .None;
	private delegate bool(char32 c) mCustomPredicate ~ delete _;

	public this() { }

	public InputFilterMode Mode
	{
		get => mMode;
		set => mMode = value;
	}

	/// A predicate of its own, which it takes and owns (the mode becomes Custom).
	public void SetCustomFilter(delegate bool(char32 c) predicate)
	{
		if (predicate !== mCustomPredicate)
			delete mCustomPredicate;
		mCustomPredicate = predicate;
		mMode = .Custom;
	}

	/// Whether it lets `c` in.
	public bool Accept(char32 c)
	{
		switch (mMode)
		{
		case .None:
			return true;
		case .Digits:
			return (c >= '0') && (c <= '9');
		case .HexDigits:
			return ((c >= '0') && (c <= '9')) || ((c >= 'a') && (c <= 'f')) || ((c >= 'A') && (c <= 'F'));
		case .Custom:
			return (mCustomPredicate != null) ? mCustomPredicate(c) : true;
		}
	}

	/// A filter of digits, which the caller owns.
	public static InputFilter Digits()
	{
		let f = new InputFilter();
		f.mMode = .Digits;
		return f;
	}

	/// A filter of hex digits, which the caller owns.
	public static InputFilter HexDigits()
	{
		let f = new InputFilter();
		f.mMode = .HexDigits;
		return f;
	}
}
