using System;

namespace Sedulous.UI;

/// Filters characters before they reach a text control.
///
/// Self contained: it holds a mode and, at most, one predicate, and knows nothing about views.
class InputFilter
{
	private InputFilterMode mMode = .None;
	private delegate bool(char32 character) mCustomPredicate ~ delete _;

	public this() {}

	public InputFilterMode Mode
	{
		get => mMode;
		set { mMode = value; }
	}

	/// Sets a custom predicate, which also switches the mode to Custom. OWNERSHIP of the
	/// delegate transfers, and a second call deletes the first.
	public void SetCustomFilter(delegate bool(char32 character) predicate)
	{
		delete mCustomPredicate;
		mCustomPredicate = predicate;
		mMode = .Custom;
	}

	/// Whether this filter accepts the character.
	public bool Accept(char32 character)
	{
		switch (mMode)
		{
		case .None:
			return true;
		case .Digits:
			return (character >= '0') && (character <= '9');
		case .HexDigits:
			return ((character >= '0') && (character <= '9'))
				|| ((character >= 'a') && (character <= 'f'))
				|| ((character >= 'A') && (character <= 'F'));
		case .Custom:
			// A Custom mode with no predicate accepts everything rather than nothing: a
			// half configured filter should not silently swallow every keystroke.
			return (mCustomPredicate != null) ? mCustomPredicate(character) : true;
		}
	}

	/// The caller owns the filter.
	public static InputFilter Digits()
	{
		let filter = new InputFilter();
		filter.mMode = .Digits;
		return filter;
	}

	/// The caller owns the filter.
	public static InputFilter HexDigits()
	{
		let filter = new InputFilter();
		filter.mMode = .HexDigits;
		return filter;
	}
}
