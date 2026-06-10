namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Parses .sss stylesheet text into a StyleSheet.
/// Used internally by StyleSheetLoader.
public class SSSParser
{
	private List<Token> mTokens ~ delete _;
	private int mPos;
	private Dictionary<String, Color> mPalette;
	private Dictionary<String, String> mSvgRegistry;
	private Dictionary<String, IImageData> mImageRegistry;
	private IResourceProvider mResourceProvider;
	private StyleSheet mSheet;
	private String mBasePath;

	public this(List<Token> tokens, Dictionary<String, Color> palette,
		Dictionary<String, String> svgRegistry, Dictionary<String, IImageData> imageRegistry,
		IResourceProvider resourceProvider, String basePath)
	{
		mTokens = tokens;
		mPalette = palette;
		mSvgRegistry = svgRegistry;
		mImageRegistry = imageRegistry;
		mResourceProvider = resourceProvider;
		mBasePath = basePath;
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

	// === Directives ===

	private void ParseDirective()
	{
		let dir = Consume();
		if (dir.Text == "@palette")       ParsePaletteDirective();
		else if (dir.Text == "@icon")     ParseIconDirective();
		else if (dir.Text == "@image")    ParseImageDirective();
		else if (dir.Text == "@import")   ParseImportDirective();
		else                              SkipUntilSemicolon();
	}

	private void ParsePaletteDirective()
	{
		// @palette name { ... }
		// @palette name extends parent { ... }
		ConsumeIdent(); // palette name (for future multi-palette support)

		if (Peek().Kind == .Extends)
		{
			Consume(); // eat "extends"
			ConsumeIdent(); // parent name (base palette already loaded)
		}

		Expect(.LBrace);
		while (!IsAtEnd() && Peek().Kind != .RBrace)
		{
			let varName = ConsumeIdent();
			Expect(.Colon);
			let color = ParseColorValue();

			// Update or add to palette
			bool found = false;
			for (let kv in mPalette)
			{
				if (StringView(kv.key) == varName)
				{
					mPalette[kv.key] = color;
					found = true;
					break;
				}
			}
			if (!found)
				mPalette[new String(varName)] = color;

			MatchSemicolon();
		}
		Expect(.RBrace);
	}

	private void ParseIconDirective()
	{
		// @icon name "path";
		// Registers SVG by loading from file via resource provider.
		let name = ConsumeIdent();
		let path = ConsumeString();
		MatchSemicolon();

		if (mResourceProvider != null && path.Length > 0)
		{
			let resolvedPath = ResolvePath(path);
			defer delete resolvedPath;
			let svgText = new String();
			if (mResourceProvider.LoadText(resolvedPath, svgText) case .Ok)
			{
				// Replace or add to SVG registry
				for (let kv in mSvgRegistry)
				{
					if (StringView(kv.key) == name)
					{
						delete mSvgRegistry[kv.key];
						mSvgRegistry[kv.key] = svgText;
						return;
					}
				}
				mSvgRegistry[new String(name)] = svgText;
			}
			else
				delete svgText;
		}
	}

	private void ParseImageDirective()
	{
		// @image name "path";
		let name = ConsumeIdent();
		let path = ConsumeString();
		MatchSemicolon();

		if (mResourceProvider != null && path.Length > 0)
		{
			let resolvedPath = ResolvePath(path);
			defer delete resolvedPath;
			if (mResourceProvider.LoadImage(resolvedPath) case .Ok(let imageData))
			{
				for (let kv in mImageRegistry)
				{
					if (StringView(kv.key) == name)
					{
						mImageRegistry[kv.key] = imageData;
						return;
					}
				}
				mImageRegistry[new String(name)] = imageData;
			}
		}
	}

	private void ParseImportDirective()
	{
		// @import "path.sss";
		let path = ConsumeString();
		MatchSemicolon();

		if (mResourceProvider != null && path.Length > 0)
		{
			let resolvedPath = ResolvePath(path);
			defer delete resolvedPath;
			let importText = scope String();
			if (mResourceProvider.LoadText(resolvedPath, importText) case .Ok)
			{
				// Tokenize and parse the imported file, sharing our palette/registries.
				let importTokenizer = scope Tokenizer(importText);
				let importTokens = new List<Token>();
				importTokenizer.TokenizeAll(importTokens);

				// Compute base path for the import
				let importBase = new String(resolvedPath);
				let lastSlash = Math.Max(importBase.LastIndexOf('/'), importBase.LastIndexOf('\\'));
				if (lastSlash >= 0)
					importBase.RemoveToEnd(lastSlash + 1);
				else
					importBase.Clear();

				let importParser = scope SSSParser(importTokens, mPalette,
					mSvgRegistry, mImageRegistry, mResourceProvider, importBase);
				let importSheet = importParser.Parse();

				// Merge imported rules into our sheet
				// We take ownership by moving rules
				for (int i = 0; i < importSheet.[Friend]mRules.Count; i++)
				{
					let rule = importSheet.[Friend]mRules[i];
					mSheet.AddRule(rule);
				}
				// Clear rules from import sheet so it doesn't delete them
				importSheet.[Friend]mRules.Clear();

				// Move owned drawables
				for (let d in importSheet.[Friend]mOwnedDrawables)
					mSheet.OwnDrawable(d);
				importSheet.[Friend]mOwnedDrawables.Clear();

				// Move owned resources
				for (let r in importSheet.[Friend]mOwnedResources)
					mSheet.OwnResource(r);
				importSheet.[Friend]mOwnedResources.Clear();

				importSheet.ReleaseRef();
				delete importBase;
			}
		}
	}

	// === Rules ===

	private void ParseRule()
	{
		// Selector: Type.class.class:state:state { ... }
		let rule = new StyleRule();

		// Type selector
		if (Peek().Kind == .Ident)
		{
			let typeName = Peek().Text;
			let type = UITypeRegistry.Resolve(typeName);
			if (type != null)
			{
				Consume();
				rule.Selector.ViewType = type;
			}
		}

		// Class selectors
		while (Peek().Kind == .ClassSelector)
		{
			let cls = Consume();
			rule.Selector.AddClass(cls.Text.Substring(1)); // skip leading .
		}

		// Pseudo-states (:hover, :checked, etc.) — may be multiple for compound states
		var state = ControlState.Normal;
		bool hasState = false;
		while (Peek().Kind == .PseudoState)
		{
			let ps = Consume();
			state |= ParsePseudoStateName(ps.Text.Substring(1)); // skip leading :
			hasState = true;
		}
		if (hasState)
			rule.Selector.State = state;

		// Pseudo-element (::thumb, ::track, etc.)
		// Tokenizer produces :: as Colon + PseudoState(:name), since the
		// second : followed by a letter is read as a PseudoState token.
		if (Peek().Kind == .Colon && mPos + 1 < mTokens.Count && mTokens[mPos + 1].Kind == .PseudoState)
		{
			Consume(); // first : (Colon)
			let ps = Consume(); // :name (PseudoState)
			rule.Selector.SetPseudoElement(ps.Text.Substring(1)); // skip leading :
		}

		// Allow :state after ::pseudo (e.g., ::tab:hover)
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
		if (prop == null)
		{
			// Unknown property — skip to semicolon
			SkipUntilSemicolonOrBrace();
			return;
		}

		// String-valued properties (font-family, etc) skip the
		// StyleValue wrapper: ParseStyleValue would have to allocate a
		// String just for the dispatch to copy it again. rule.Set's
		// StringView overload owns its own copy.
		if (IsStringProperty(prop.Value))
		{
			let s = ParseStringOrIdent();
			if (s.Length > 0)
				rule.Set(prop.Value, s);
			MatchSemicolon();
			return;
		}

		let value = ParseStyleValue(prop.Value);
		if (!(value case .None))
		{
			switch (value)
			{
			case .ColorVal(let c):     rule.Set(prop.Value, c);
			case .FloatVal(let f):     rule.Set(prop.Value, f);
			case .ThicknessVal(let t): rule.Set(prop.Value, t);
			case .DrawableRef(let d):  rule.Set(prop.Value, d);
			case .BoolVal(let b):      rule.Set(prop.Value, b);
			default:
			}
		}

		MatchSemicolon();
	}

	// === Value parsing (public for DrawableFactoryRegistry) ===

	/// Parse a color value: hex, named, rgb(), rgba(), $variable, or color function.
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

	/// Parse a color argument inside a function call (for drawable factories).
	public Color ParseColorArg() => ParseColorValue();

	/// Parse a float value (number, possibly followed by %).
	public float ParseFloatValue()
	{
		if (Peek().Kind == .Number)
		{
			let tok = Consume();
			var val = tok.NumericValue;
			if (Peek().Kind == .Percent) { Consume(); val /= 100.0f; }
			return val;
		}
		if (Peek().Kind == .Variable)
		{
			Consume(); // variable as float not supported yet
			return 0;
		}
		return 0;
	}

	/// Parse a drawable value: factory call or color literal -> ColorDrawable.
	public Drawable ParseDrawableValue(StyleSheet sheet)
	{
		if (Peek().Kind == .Ident)
		{
			let factory = DrawableFactoryRegistry.Get(Peek().Text);
			if (factory != null)
			{
				Consume(); // function name
				Expect(.LParen);
				let d = factory(this, sheet);
				Expect(.RParen);
				return d;
			}
		}
		// Color literal as ColorDrawable
		let color = ParseColorValue();
		let d = new ColorDrawable(color);
		sheet.OwnDrawable(d);
		return d;
	}

	/// Check if next token is a comma and consume it.
	public bool MatchComma()
	{
		if (Peek().Kind == .Comma) { Consume(); return true; }
		return false;
	}

	/// Check if we're at a closing paren.
	public bool IsAtRParen() => Peek().Kind == .RParen;

	/// Peek at keyword arg name (e.g., "radius" in "radius=6").
	public StringView PeekKeywordArg()
	{
		if (Peek().Kind == .Ident && mPos + 1 < mTokens.Count && mTokens[mPos + 1].Kind == .Equals)
			return Peek().Text;
		return "";
	}

	/// Consume keyword arg name and equals sign.
	public void ConsumeKeywordArg()
	{
		Consume(); // name
		Consume(); // =
	}

	/// Peek at current ident text without consuming.
	public StringView PeekIdent()
	{
		if (Peek().Kind == .Ident) return Peek().Text;
		return "";
	}

	/// Check if next token is a number.
	public bool PeekIsNumber() => Peek().Kind == .Number;

	/// Resolve a registered SVG by name. Returns the SVG text or null.
	public StringView? ResolveSvg(StringView name)
	{
		for (let kv in mSvgRegistry)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return default;
	}

	/// Resolve a registered image by name. Returns the image data or null.
	public IImageData ResolveImage(StringView name)
	{
		for (let kv in mImageRegistry)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}

	// === Private value parsing ===

	private StyleValue ParseStyleValue(StyleProperty prop)
	{
		if (IsDrawableProperty(prop))
		{
			let d = ParseDrawableValue(mSheet);
			if (d != null) return .DrawableRef(d);
			return .None;
		}
		if (IsColorProperty(prop))
			return .ColorVal(ParseColorValue());
		if (IsThicknessProperty(prop))
			return .ThicknessVal(ParseThicknessValue());
		if (IsBoolProperty(prop))
		{
			if (Peek().Kind == .BoolLit)
				return .BoolVal(Consume().Text == "true");
			return .None;
		}
		// Default: float
		return .FloatVal(ParseFloatValue());
	}

	private Color ParseRgbFunction()
	{
		Consume(); // rgb/rgba
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
		float[4] values = default;
		int count = 0;
		while (count < 4 && Peek().Kind == .Number)
			values[count++] = ParseFloatValue();
		return StyleValueParser.ParseThickness(&values, count);
	}

	// === Property name resolution (all ~48 properties) ===

	private static StyleProperty? ResolvePropertyName(StringView name)
	{
		// Drawable properties
		if (name == "background") return .Background;
		if (name == "checked-background") return .CheckedBackground;
		if (name == "menu-item-hover-drawable") return .MenuItemHoverDrawable;

		// Color properties
		if (name == "text-color") return .TextColor;
		if (name == "text-dim-color") return .TextDimColor;
		if (name == "placeholder-color") return .PlaceholderColor;
		if (name == "border-color") return .BorderColor;
		if (name == "cursor-color") return .CursorColor;
		if (name == "selection-color") return .SelectionColor;
		if (name == "accent-color") return .AccentColor;

		// Float properties
		if (name == "font-size") return .FontSize;
		if (name == "corner-radius") return .CornerRadius;

		// String properties
		if (name == "font-family") return .FontFamily;
		if (name == "border-width") return .BorderWidth;
		if (name == "spacing") return .Spacing;
		if (name == "opacity") return .Opacity;
		if (name == "width") return .Width;
		if (name == "height") return .Height;

		// Thickness properties
		if (name == "padding") return .Padding;
		if (name == "margin") return .Margin;

		// Bool properties
		if (name == "word-wrap") return .WordWrap;

		return null;
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

	private static bool IsDrawableProperty(StyleProperty prop)
	{
		return prop <= .MenuItemHoverDrawable;
	}

	private static bool IsColorProperty(StyleProperty prop)
	{
		return prop >= .TextColor && prop <= .AccentColor;
	}

	private static bool IsThicknessProperty(StyleProperty prop)
	{
		return prop == .Padding || prop == .Margin;
	}

	private static bool IsBoolProperty(StyleProperty prop)
	{
		return prop == .WordWrap;
	}

	private static bool IsStringProperty(StyleProperty prop)
	{
		return prop == .FontFamily;
	}

	/// Read a quoted string literal or a bare identifier (e.g.
	/// `font-family: "Jungle Adventurer"` or
	/// `font-family: JungleAdventurer`).
	private StringView ParseStringOrIdent()
	{
		if (Peek().Kind == .StringLit) return Consume().Text;
		if (Peek().Kind == .Ident) return Consume().Text;
		return "";
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
		return .White; // unresolved variable
	}

	// === Path resolution ===

	private String ResolvePath(StringView path)
	{
		if (mBasePath != null && mBasePath.Length > 0)
		{
			let resolved = new String();
			resolved.Append(mBasePath);
			resolved.Append(path);
			return resolved;
		}
		return new String(path);
	}

	// === Token helpers ===

	private Token Peek() => (mPos < mTokens.Count) ? mTokens[mPos] : Token(.EOF, "", 0, 0);
	private Token Consume() => (mPos < mTokens.Count) ? mTokens[mPos++] : Token(.EOF, "", 0, 0);
	private bool IsAtEnd() => mPos >= mTokens.Count || mTokens[mPos].Kind == .EOF;

	public StringView ConsumeIdent()
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
