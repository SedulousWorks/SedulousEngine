namespace Sedulous.UI;

using System;

/// Predefined input filter modes.
public enum InputFilterMode
{
	None,
	Digits,
	HexDigits,
	Custom
}

/// Filters characters before insertion into a text control.
public class InputFilter
{
	private InputFilterMode mMode = .None;
	private delegate bool(char32) mCustomPredicate ~ delete _;

	public InputFilterMode Mode
	{
		get => mMode;
		set => mMode = value;
	}

	/// Set a custom character predicate. Takes ownership of the delegate.
	public void SetCustomFilter(delegate bool(char32) predicate)
	{
		delete mCustomPredicate;
		mCustomPredicate = predicate;
		mMode = .Custom;
	}

	/// Returns true if the character is accepted by this filter.
	public bool Accept(char32 c)
	{
		switch (mMode)
		{
		case .None:
			return true;
		case .Digits:
			return c >= '0' && c <= '9';
		case .HexDigits:
			return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
		case .Custom:
			if (mCustomPredicate != null)
				return mCustomPredicate(c);
			return true;
		}
	}

	/// Create a digits-only filter.
	public static InputFilter Digits()
	{
		let f = new InputFilter();
		f.mMode = .Digits;
		return f;
	}

	/// Create a hex digits filter.
	public static InputFilter HexDigits()
	{
		let f = new InputFilter();
		f.mMode = .HexDigits;
		return f;
	}
}
