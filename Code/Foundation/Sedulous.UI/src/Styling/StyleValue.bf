using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A tagged value stored in a style rule.
///
/// DIVERGES from Raptor in WHO OWNS the payloads. Raptor holds the drawable, the variable
/// reference and the transition list as RefPtr members, so copying a StyleValue refcounts
/// them. A Beef struct has neither a copy constructor nor a destructor, so those members are
/// BORROWED here and the StyleSheet owns them, which is where Raptor already keeps them too:
/// its OwnDrawable and OwnResource arrays are the real owner and the RefPtrs are belt and
/// braces on top.
///
/// A StyleValue is therefore valid for as long as the sheet that produced it. That is already
/// how consumers treat it, Raptor's own accessors being documented as borrowing, and a sheet
/// swap ends every running transition rather than leaving values behind pointing at rules
/// that have gone.
struct StyleValue
{
	public enum Kind
	{
		None,
		Color,
		Float,
		Thickness,
		Drawable,
		Bool,
		String,
		/// A length carrying units: percentages, em, and calc sums. A plain number stays a
		/// Float.
		Length,
		Shadow,
		Transitions,
		/// The `inherit` keyword: take the parent's computed value.
		Inherit,
		/// The `initial` keyword: as if never set.
		Initial,
		/// A `var(--name, fallback)` reference.
		Variable
	}

	private Kind mKind = .None;
	private Color mColor = .();
	private float mFloat = 0.0f;
	private Thickness mThickness = .();
	private bool mBool = false;
	private Unit mLength = .();
	private BoxShadow mShadow = .();
	// Borrowed; the sheet owns these.
	private Drawable mDrawable = null;
	private StringView mString = default;
	private VariableReference mVariable = null;
	private TransitionList mTransitions = null;

	public this() {}

	public static StyleValue ColorVal(Color value)
	{
		StyleValue v = .();
		v.mKind = .Color;
		v.mColor = value;
		return v;
	}

	public static StyleValue FloatVal(float value)
	{
		StyleValue v = .();
		v.mKind = .Float;
		v.mFloat = value;
		return v;
	}

	public static StyleValue ThicknessVal(Thickness value)
	{
		StyleValue v = .();
		v.mKind = .Thickness;
		v.mThickness = value;
		return v;
	}

	/// BORROWS the drawable; the sheet keeps it alive.
	public static StyleValue DrawableRef(Drawable value)
	{
		StyleValue v = .();
		v.mKind = .Drawable;
		v.mDrawable = value;
		return v;
	}

	public static StyleValue BoolVal(bool value)
	{
		StyleValue v = .();
		v.mKind = .Bool;
		v.mBool = value;
		return v;
	}

	/// BORROWS the text; the sheet keeps the backing alive.
	public static StyleValue StringRef(StringView value)
	{
		StyleValue v = .();
		v.mKind = .String;
		v.mString = value;
		return v;
	}

	public static StyleValue LengthVal(Unit value)
	{
		StyleValue v = .();
		v.mKind = .Length;
		v.mLength = value;
		return v;
	}

	public static StyleValue ShadowVal(BoxShadow value)
	{
		StyleValue v = .();
		v.mKind = .Shadow;
		v.mShadow = value;
		return v;
	}

	/// BORROWS the list; the sheet keeps it alive.
	public static StyleValue TransitionsRef(TransitionList value)
	{
		StyleValue v = .();
		v.mKind = .Transitions;
		v.mTransitions = value;
		return v;
	}

	public static StyleValue Inherit()
	{
		StyleValue v = .();
		v.mKind = .Inherit;
		return v;
	}

	public static StyleValue Initial()
	{
		StyleValue v = .();
		v.mKind = .Initial;
		return v;
	}

	/// BORROWS the reference; the sheet keeps it alive.
	public static StyleValue VariableRef(VariableReference reference)
	{
		StyleValue v = .();
		v.mKind = .Variable;
		v.mVariable = reference;
		return v;
	}

	public static StyleValue None() => .();

	public Kind GetKind() => mKind;
	public bool IsNone => mKind == .None;

	/// Whether the cascade still has to turn this into a concrete value.
	public bool NeedsResolution =>
		(mKind == .Inherit) || (mKind == .Initial) || (mKind == .Variable);

	public Color? AsColor => (mKind == .Color) ? mColor : null;
	public float? AsFloat => (mKind == .Float) ? mFloat : null;
	public Thickness? AsThickness => (mKind == .Thickness) ? mThickness : null;
	public bool? AsBool => (mKind == .Bool) ? mBool : null;
	public Unit? AsLength => (mKind == .Length) ? mLength : null;
	public BoxShadow? AsShadow => (mKind == .Shadow) ? mShadow : null;

	/// Borrowed, and null when the kind differs.
	public Drawable AsDrawable => (mKind == .Drawable) ? mDrawable : null;
	public VariableReference Variable => (mKind == .Variable) ? mVariable : null;
	public TransitionList AsTransitions => (mKind == .Transitions) ? mTransitions : null;

	/// Borrowed, and empty when the kind differs.
	public StringView? AsString => (mKind == .String) ? mString : null;
}
