using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A tagged value stored in a style rule.
///
/// A payload enum, which is what Beef is built for: exactly one payload exists and the
/// compiler will not let you reach the others. A class holding every payload side by side
/// plus a Kind would cost about a hundred and thirty bytes per value where this costs
/// around thirty two, and would let a caller read a payload the tag says is not there.
///
/// The reference payloads are BORROWED: the StyleRule holding the value owns them, since an
/// enum has no destructor to release anything with.
enum StyleValue
{
	case None;
	case Color(Color value);
	case Float(float value);
	case Thickness(Thickness value);
	/// Borrowed.
	case Drawable(Drawable value);
	case Bool(bool value);
	/// Borrowed.
	case String(StringView value);
	case Length(Unit value);
	case Shadow(BoxShadow value);
	/// Borrowed.
	case Transitions(TransitionList value);
	/// Take the parent's computed value.
	case Inherit;
	/// As if never set.
	case Initial;
	/// Borrowed.
	case Variable(VariableReference value);

	public StyleValueKind Kind
	{
		get
		{
			switch (this)
			{
			case .None: return .None;
			case .Color: return .Color;
			case .Float: return .Float;
			case .Thickness: return .Thickness;
			case .Drawable: return .Drawable;
			case .Bool: return .Bool;
			case .String: return .String;
			case .Length: return .Length;
			case .Shadow: return .Shadow;
			case .Transitions: return .Transitions;
			case .Inherit: return .Inherit;
			case .Initial: return .Initial;
			case .Variable: return .Variable;
			}
		}
	}

	public bool IsNone => this case .None;

	/// Whether the cascade still has to turn this into a concrete value.
	public bool NeedsResolution
	{
		get
		{
			switch (this)
			{
			case .Inherit, .Initial, .Variable: return true;
			default: return false;
			}
		}
	}

	public Color? AsColor
	{
		get
		{
			if (this case .Color(let value))
				return value;
			return null;
		}
	}

	public float? AsFloat
	{
		get
		{
			if (this case .Float(let value))
				return value;
			return null;
		}
	}

	public Thickness? AsThickness
	{
		get
		{
			if (this case .Thickness(let value))
				return value;
			return null;
		}
	}

	public bool? AsBool
	{
		get
		{
			if (this case .Bool(let value))
				return value;
			return null;
		}
	}

	public Unit? AsLength
	{
		get
		{
			if (this case .Length(let value))
				return value;
			return null;
		}
	}

	public BoxShadow? AsShadow
	{
		get
		{
			if (this case .Shadow(let value))
				return value;
			return null;
		}
	}

	/// Borrowed, and null when the kind differs.
	public Drawable AsDrawable
	{
		get
		{
			if (this case .Drawable(let value))
				return value;
			return null;
		}
	}

	/// Borrowed, and null when the kind differs.
	public TransitionList AsTransitions
	{
		get
		{
			if (this case .Transitions(let value))
				return value;
			return null;
		}
	}

	/// Borrowed, and null when the kind differs.
	public VariableReference AsVariable
	{
		get
		{
			if (this case .Variable(let value))
				return value;
			return null;
		}
	}

	/// Borrowed, and null when the kind differs.
	public StringView? AsString
	{
		get
		{
			if (this case .String(let value))
				return value;
			return null;
		}
	}
}
