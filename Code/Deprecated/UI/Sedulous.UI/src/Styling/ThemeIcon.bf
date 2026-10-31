using System;

namespace Sedulous.UI;

/// The built in chrome glyphs.
enum ThemeIcon : uint8
{
	case Checkmark;
	case ArrowDown;
	case ArrowUp;
	case ChevronRight;
	case ChevronDown;
	case Close;
	case Plus;
	case Minus;
	case RadioMarkSquare;
	case RadioMarkRound;

	/// The kebab case name a style sheet writes, which is the `svg(name)` factory's fallback
	/// vocabulary and what the cook validates names against. Null when the name is not one of
	/// the built ins.
	public static ThemeIcon? FromName(StringView name)
	{
		switch (name)
		{
		case "checkmark": return .Checkmark;
		case "arrow-down": return .ArrowDown;
		case "arrow-up": return .ArrowUp;
		case "chevron-right": return .ChevronRight;
		case "chevron-down": return .ChevronDown;
		case "close": return .Close;
		case "plus": return .Plus;
		case "minus": return .Minus;
		case "radio-mark-square": return .RadioMarkSquare;
		case "radio-mark-round": return .RadioMarkRound;
		default: return null;
		}
	}

	/// The glyph's SVG source.
	public StringView Svg
	{
		get
		{
			switch (this)
			{
			case .Checkmark: return ThemeIcons.Checkmark;
			case .ArrowDown: return ThemeIcons.ArrowDown;
			case .ArrowUp: return ThemeIcons.ArrowUp;
			case .ChevronRight: return ThemeIcons.ChevronRight;
			case .ChevronDown: return ThemeIcons.ChevronDown;
			case .Close: return ThemeIcons.Close;
			case .Plus: return ThemeIcons.Plus;
			case .Minus: return ThemeIcons.Minus;
			case .RadioMarkSquare: return ThemeIcons.RadioMarkSquare;
			case .RadioMarkRound: return ThemeIcons.RadioMarkRound;
			}
		}
	}
}
