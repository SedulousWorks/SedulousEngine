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
	/// One shadow (a box-shadow of one, or a text effect).
	case Shadow(BoxShadow value);
	/// A box-shadow of two or more, the first on top. Borrowed.
	case Shadows(BoxShadowList value);
	/// A sheet's transform.
	case Transform(StyleTransform value);
	/// Borrowed.
	case Animations(AnimationList value);
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
			case .Shadow, .Shadows: return .Shadow;
			case .Transform: return .Transform;
			case .Animations: return .Animations;
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

	/// Borrowed, and null when the kind differs.
	public AnimationList AsAnimations
	{
		get
		{
			if (this case .Animations(let value))
				return value;
			return null;
		}
	}

	public StyleTransform? AsTransform
	{
		get
		{
			if (this case .Transform(let value))
				return value;
			return null;
		}
	}

	/// The first shadow (a text effect's only one).
	public BoxShadow? AsShadow
	{
		get
		{
			if (this case .Shadow(let value))
				return value;
			if ((this case .Shadows(let list)) && (list.Count > 0))
				return list[0];
			return null;
		}
	}

	/// How many shadows the value holds: none for a value that is no shadow.
	public int ShadowCount
	{
		get
		{
			if (this case .Shadow)
				return 1;
			if (this case .Shadows(let list))
				return list.Count;
			return 0;
		}
	}

	/// The shadow at `index` (below ShadowCount), the first painted on top.
	public BoxShadow ShadowAt(int index)
	{
		if (this case .Shadows(let list))
			return list[index];
		return AsShadow.Value;
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
