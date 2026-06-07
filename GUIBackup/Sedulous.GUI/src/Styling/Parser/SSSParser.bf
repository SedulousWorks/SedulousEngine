namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Parses .sss stylesheet text into a StyleSheet.
public class SSSParser
{
	private List<Token> mTokens ~ delete _;
	private int mPos;
	private Dictionary<String, Color> mPalette = new .() ~ DeleteDictionaryAndKeys!(_);
	private Dictionary<String, String> mIcons = new .() ~ { DeleteDictionaryAndKeysAndValues!(_); };
	private StyleSheet mSheet;

	public this(List<Token> tokens)
	{
		mTokens = tokens;
	}

	public StyleSheet Parse()
	{
		mSheet = new StyleSheet();
		mPos = 0;

		while (!IsAtEnd())
		{
			if (Peek().Kind == .Directive)
				ParseDirective();
			else
				ParseRule();
		}

		return mSheet;
	}

	public StyleSheet Parse(Dictionary<String, Color> basePalette)
	{
		for (let kv in basePalette)
			mPalette[new String(kv.key)] = kv.value;
		return Parse();
	}

	public Dictionary<String, Color> GetPalette() => mPalette;

	// === Directives ===

	private void ParseDirective()
	{
		let dir = Consume();
		if (dir.Text == "@palette")       ParsePaletteDirective();
		else if (dir.Text == "@icon")     ParseIconDirective();
		else if (dir.Text == "@import")   ParseImportDirective();
		else                              SkipUntilSemicolon();
	}

	private void ParsePaletteDirective()
	{
		ConsumeIdent(); // palette name — for multi-palette support later

		if (Peek().Kind == .Extends)
		{
			Consume();
			ConsumeIdent(); // parent palette name
		}

		Expect(.LBrace);
		while (!IsAtEnd() && Peek().Kind != .RBrace)
		{
			let varName = ConsumeIdent();
			Expect(.Colon);
			let color = ParseColorValue();
			mPalette[new String(varName)] = color;
			MatchSemicolon();
		}
		Expect(.RBrace);
	}

	private void ParseIconDirective()
	{
		let name = ConsumeIdent();
		let path = ConsumeString();
		mIcons[new String(name)] = new String(path);
		MatchSemicolon();
	}

	private void ParseImportDirective()
	{
		ConsumeString(); // path — StyleSheetLoader handles actual file loading
		MatchSemicolon();
	}

	// === Rules ===

	private void ParseRule()
	{
		// Selector: Type.class.class:state::pseudo { ... }
		let rule = new StyleRule();

		// Type selector
		if (Peek().Kind == .Ident)
		{
			let typeName = ConsumeIdent();
			let type = UITypeRegistry.Resolve(typeName);
			if (type != null)
				rule.Selector.ViewType = type;
		}

		// Class selectors
		while (Peek().Kind == .ClassSelector)
		{
			let cls = Consume();
			rule.Selector.AddClass(cls.Text.Substring(1));
		}

		// Pseudo-states (:hover, :checked, etc.)
		var state = ControlState.Normal;
		bool hasState = false;
		while (Peek().Kind == .PseudoState)
		{
			let ps = Consume();
			state |= ParsePseudoStateName(ps.Text.Substring(1));
			hasState = true;
		}
		if (hasState)
			rule.Selector.State = state;

		// Pseudo-element (::thumb, ::track, etc.)
		// Tokenizer produces : as Colon. So :: is Colon + Colon.
		if (Peek().Kind == .Colon && mPos + 1 < mTokens.Count && mTokens[mPos + 1].Kind == .Colon)
		{
			Consume(); // first :
			Consume(); // second :
			if (Peek().Kind == .Ident)
				rule.Selector.SetPseudoElement(ConsumeIdent());
		}

		// Also check for :state after ::pseudo (e.g., ::tab:hover)
		while (Peek().Kind == .PseudoState)
		{
			let ps = Consume();
			state |= ParsePseudoStateName(ps.Text.Substring(1));
			hasState = true;
		}
		if (hasState)
			rule.Selector.State = state;

		// Property block
		Expect(.LBrace);
		while (!IsAtEnd() && Peek().Kind != .RBrace)
			ParseProperty(rule);
		Expect(.RBrace);

		mSheet.AddRule(rule);
	}

	private void ParseProperty(StyleRule rule)
	{
		let propName = ConsumeIdent();
		Expect(.Colon);

		let prop = ResolvePropertyName(propName);
		if (prop == .COUNT)
		{
			SkipUntilSemicolonOrBrace();
			return;
		}

		let value = ParseStyleValue(prop);
		if (!(value case .None))
		{
			switch (value)
			{
			case .ColorVal(let c):     rule.Set(prop, c);
			case .FloatVal(let f):     rule.Set(prop, f);
			case .ThicknessVal(let t): rule.Set(prop, t);
			case .DrawableRef(let d):  rule.Set(prop, d);
			case .BoolVal(let b):      rule.Set(prop, b);
			default:
			}
		}

		MatchSemicolon();
	}

	// === Value parsing (public for DrawableFactoryRegistry) ===

	public Color ParseColorValue()
	{
		if (Peek().Kind == .HexColor)
		{
			let tok = Consume();
			if (StyleValueParser.ParseHexColor(tok.Text) case .Ok(let c))
				return c;
			return .White;
		}
		if (Peek().Kind == .Variable)
		{
			let tok = Consume();
			return ResolveVariable(tok.Text);
		}
		if (Peek().Kind == .Ident)
		{
			let name = Peek().Text;
			if (StyleValueParser.ParseNamedColor(name) case .Ok(let c))
			{
				Consume();
				return c;
			}
			if (name == "rgb" || name == "rgba")
				return ParseRgbFunction();
			if (name == "lighten" || name == "darken" || name == "alpha" || name == "mix")
				return ParseColorFunction();
		}
		return .White;
	}

	public Color ParseColorArg() => ParseColorValue();

	public float ParseFloatValue()
	{
		if (Peek().Kind == .Number)
		{
			let tok = Consume();
			var val = tok.NumericValue;
			if (Peek().Kind == .Percent) { Consume(); val /= 100.0f; }
			return val;
		}
		if (Peek().Kind == .Variable) { Consume(); return 0; }
		return 0;
	}

	public Drawable ParseDrawableValue(StyleSheet sheet)
	{
		if (Peek().Kind == .Ident)
		{
			let factory = DrawableFactoryRegistry.Get(Peek().Text);
			if (factory != null)
			{
				Consume();
				Expect(.LParen);
				let d = factory(this, sheet);
				Expect(.RParen);
				return d;
			}
		}
		let color = ParseColorValue();
		let d = new ColorDrawable(color);
		sheet.OwnDrawable(d);
		return d;
	}

	public bool MatchComma()
	{
		if (Peek().Kind == .Comma) { Consume(); return true; }
		return false;
	}

	public bool IsAtRParen() => Peek().Kind == .RParen;

	public StringView PeekKeywordArg()
	{
		if (Peek().Kind == .Ident && mPos + 1 < mTokens.Count && mTokens[mPos + 1].Kind == .Equals)
			return Peek().Text;
		return "";
	}

	public void ConsumeKeywordArg()
	{
		Consume(); // name
		Consume(); // =
	}

	// === Private value parsing ===

	private StyleValue ParseStyleValue(StyleProperty prop)
	{
		if (prop == .Background)
		{
			let d = ParseDrawableValue(mSheet);
			if (d != null) return .DrawableRef(d);
			return .None;
		}
		if (IsColorProperty(prop))
			return .ColorVal(ParseColorValue());
		if (IsThicknessProperty(prop))
			return .ThicknessVal(ParseThicknessValue());
		if (prop == .WordWrap)
		{
			if (Peek().Kind == .BoolLit)
				return .BoolVal(Consume().Text == "true");
			return .None;
		}
		return .FloatVal(ParseFloatValue());
	}

	private Color ParseRgbFunction()
	{
		Consume();
		Expect(.LParen);
		let r = (uint8)ParseFloatValue(); MatchComma();
		let g = (uint8)ParseFloatValue(); MatchComma();
		let b = (uint8)ParseFloatValue();
		uint8 a = 255;
		if (MatchComma()) a = (uint8)(ParseFloatValue() * 255);
		Expect(.RParen);
		return .(r, g, b, a);
	}

	private Color ParseColorFunction()
	{
		let name = ConsumeIdent();
		Expect(.LParen);
		Color result = .White;

		if (name == "lighten")
		{
			let c = ParseColorValue(); MatchComma();
			result = ColorFunctions.Lighten(c, ParseFloatValue());
		}
		else if (name == "darken")
		{
			let c = ParseColorValue(); MatchComma();
			result = ColorFunctions.Darken(c, ParseFloatValue());
		}
		else if (name == "alpha")
		{
			let c = ParseColorValue(); MatchComma();
			result = ColorFunctions.Alpha(c, ParseFloatValue());
		}
		else if (name == "mix")
		{
			let a = ParseColorValue(); MatchComma();
			let b = ParseColorValue(); MatchComma();
			result = ColorFunctions.Mix(a, b, ParseFloatValue());
		}

		Expect(.RParen);
		return result;
	}

	private Thickness ParseThicknessValue()
	{
		float[] values = scope .[4];
		int count = 0;
		while (count < 4 && Peek().Kind == .Number)
			values[count++] = ParseFloatValue();
		return StyleValueParser.ParseThickness(values, count);
	}

	// === Property name resolution ===

	private static StyleProperty ResolvePropertyName(StringView name)
	{
		if (name == "background")        return .Background;
		if (name == "text-color")        return .TextColor;
		if (name == "placeholder-color") return .PlaceholderColor;
		if (name == "border-color")      return .BorderColor;
		if (name == "cursor-color")      return .CursorColor;
		if (name == "selection-color")   return .SelectionColor;
		if (name == "accent-color")      return .AccentColor;
		if (name == "font-size")         return .FontSize;
		if (name == "corner-radius")     return .CornerRadius;
		if (name == "border-width")      return .BorderWidth;
		if (name == "spacing")           return .Spacing;
		if (name == "opacity")           return .Opacity;
		if (name == "width")             return .Width;
		if (name == "height")            return .Height;
		if (name == "padding")           return .Padding;
		if (name == "margin")            return .Margin;
		if (name == "word-wrap")         return .WordWrap;
		return .COUNT;
	}

	private static ControlState ParsePseudoStateName(StringView name)
	{
		if (name == "normal")        return .Normal;
		if (name == "hover")         return .Hover;
		if (name == "pressed")       return .Pressed;
		if (name == "focused")       return .Focused;
		if (name == "disabled")      return .Disabled;
		if (name == "checked")       return .Checked;
		if (name == "indeterminate") return .Indeterminate;
		return .Normal;
	}

	private static bool IsColorProperty(StyleProperty prop)
	{
		return prop >= .TextColor && prop <= .AccentColor;
	}

	private static bool IsThicknessProperty(StyleProperty prop)
	{
		return prop == .Padding || prop == .Margin;
	}

	// === Variable resolution ===

	private Color ResolveVariable(StringView varText)
	{
		let name = (varText.Length > 0 && varText[0] == '$') ? varText.Substring(1) : varText;
		for (let kv in mPalette)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return .White;
	}

	// === Token helpers ===

	private Token Peek() => (mPos < mTokens.Count) ? mTokens[mPos] : Token(.EOF, "", 0, 0);
	private Token Consume() => (mPos < mTokens.Count) ? mTokens[mPos++] : Token(.EOF, "", 0, 0);
	private bool IsAtEnd() => mPos >= mTokens.Count || mTokens[mPos].Kind == .EOF;

	private StringView ConsumeIdent()
	{
		if (Peek().Kind == .Ident) return Consume().Text;
		return "";
	}

	private StringView ConsumeString()
	{
		if (Peek().Kind == .StringLit) return Consume().Text;
		return "";
	}

	private void Expect(TokenKind kind)
	{
		if (Peek().Kind == kind) Consume();
	}

	private bool MatchSemicolon()
	{
		if (Peek().Kind == .Semicolon) { Consume(); return true; }
		return false;
	}

	private void SkipUntilSemicolon()
	{
		while (!IsAtEnd() && Peek().Kind != .Semicolon) Consume();
		MatchSemicolon();
	}

	private void SkipUntilSemicolonOrBrace()
	{
		while (!IsAtEnd() && Peek().Kind != .Semicolon && Peek().Kind != .RBrace) Consume();
		MatchSemicolon();
	}
}
