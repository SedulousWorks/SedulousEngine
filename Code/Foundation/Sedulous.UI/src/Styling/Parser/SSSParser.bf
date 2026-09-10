using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;

namespace Sedulous.UI;

/// Parses style sheet text into a StyleSheet.
///
/// DIVERGES from Raptor in who owns a parsed drawable. Raptor refcounts, so a factory can
/// register with the sheet AND hand the same drawable to a rule or a composite. With single
/// ownership that is a double free, so ParseDrawableValue answers an OWNED reference and the
/// CALLER decides where it goes: a drawable property gives it to the sheet and lets the rule
/// borrow, while a composite factory such as state-list or layer consumes it outright.
class SSSParser
{
	/// What a compound's pseudo element parse produced. Null when the caller is an ancestor
	/// compound, which cannot carry one.
	private class PseudoElementInfo
	{
		public String Name = new .() ~ delete _;
		public bool Has = false;
		public ControlState State = .Normal;
		public bool HasState = false;
	}

	/// OWNED.
	private List<Token> mTokens ~ delete _;
	private int32 mPos = 0;

	// All BORROWED from the loader, which owns them and shares them with imported sheets.
	private Dictionary<String, Color> mPalette;
	private Dictionary<String, String> mSvgRegistry;
	private Dictionary<String, ImageData> mImageRegistry;
	private IResourceProvider mResourceProvider;

	/// The sheet being built. Owned while parsing, handed to the caller by Parse.
	private StyleSheet mSheetOwner;
	/// BORROWED: the sheet declarations are going into, which ParseDeclarations may redirect.
	private StyleSheet mSheet;
	private String mBasePath = new .() ~ delete _;

	/// OWNERSHIP of the tokens transfers. Everything else is borrowed.
	public this(List<Token> tokens, Dictionary<String, Color> palette,
		Dictionary<String, String> svgRegistry, Dictionary<String, ImageData> imageRegistry,
		IResourceProvider resourceProvider, StringView basePath)
	{
		mTokens = tokens;
		mPalette = palette;
		mSvgRegistry = svgRegistry;
		mImageRegistry = imageRegistry;
		mResourceProvider = resourceProvider;
		mBasePath.Set(basePath);
	}

	/// Parses the whole sheet. OWNERSHIP of the result transfers.
	public StyleSheet Parse()
	{
		mSheetOwner = new StyleSheet();
		mSheet = mSheetOwner;
		mPos = 0;

		while (!IsAtEnd)
		{
			if (Peek().Kind == .Directive)
				ParseDirective();
			else
				ParseRule();
		}

		let result = mSheetOwner;
		mSheetOwner = null;
		return result;
	}

	/// Parses a `style="..."` attribute body and applies it to the view's INLINE sheet.
	///
	/// Values must be literal: theme variables and the @ rules are not resolved here, because an
	/// inline attribute has no sheet around it to have declared them.
	///
	/// Any drawable a value builds is owned by the inline sheet, so it lives exactly as long as
	/// the view does.
	public static void ApplyInlineStyle(View view, StringView body)
	{
		if (view == null)
			return;

		// The drawable factories have to be registered here as well as in the sheet loader:
		// without them an inline `background: rounded-rect(...)` is simply not recognised and
		// falls back to a plain white colour rather than failing visibly.
		DrawableFactoryRegistry.RegisterBuiltins();

		let tokens = new List<Token>();
		let tokenizer = scope Tokenizer(body);
		tokenizer.TokenizeAll(tokens);

		// Empty registries, held here so they outlive the parser, which only borrows them.
		let palette = scope Dictionary<String, Color>();
		let svgRegistry = scope Dictionary<String, String>();
		let imageRegistry = scope Dictionary<String, ImageData>();

		// OWNERSHIP of the token list transfers to the parser.
		let parser = scope SSSParser(tokens, palette, svgRegistry, imageRegistry, null, "");

		// Pointed at the view's own inline sheet, so a drawable value lands on the view.
		let inlineSheet = view.GetOrCreateInlineSheet();
		parser.ParseDeclarations(inlineSheet, inlineSheet.GetOrCreateInlineElementRule());

		view.Invalidate();
	}

	/// Parses a bare declaration body, with no selectors or braces, into an existing rule.
	/// This is what a `style="..."` markup attribute is.
	public void ParseDeclarations(StyleSheet ownerSheet, StyleRule targetRule)
	{
		mSheet = ownerSheet;
		mPos = 0;
		while (!IsAtEnd)
			ParseProperty(targetRule);
	}

	// ---- Value parsing, public because the drawable factories call it --------------------------

	/// A colour: hex, named, rgb, rgba, a palette variable, or a colour function.
	public Color ParseColorValue()
	{
		if (Peek().Kind == .HexColor)
		{
			let token = Consume();
			let color = StyleValueParser.ParseHexColor(token.Text);
			if (color != null)
				return color.Value;
			return Color.White;
		}

		if (Peek().Kind == .Variable)
			return ResolveVariable(Consume().Text);

		if (Peek().Kind == .Ident)
		{
			let name = Peek().Text;
			let named = StyleValueParser.ParseNamedColor(name);
			if (named != null)
			{
				Consume();
				return named.Value;
			}
			if ((name == "rgb") || (name == "rgba"))
				return ParseRgbFunction();
			if (IsColorFunctionName(name))
				return ParseColorFunction();
		}

		// An unreadable colour is WHITE rather than a parse failure: a theme with one bad
		// colour should still load, loudly wrong rather than not at all.
		return Color.White;
	}

	private static bool IsColorFunctionName(StringView name)
	{
		switch (name)
		{
		case "lighten", "darken", "alpha", "mix", "hover", "pressed", "disabled", "focused":
			return true;
		default:
			return false;
		}
	}

	/// A colour argument inside a factory call.
	public Color ParseColorArg() => ParseColorValue();

	/// One to four numbers as per corner radii: one is uniform, four are top left, top right,
	/// bottom right and bottom left, in CSS order.
	public CornerRadii ParseCornerRadiiValue()
	{
		float[4] values = .();
		var count = 0;
		while ((count < 4) && (Peek().Kind == .Number))
		{
			values[count] = ParseFloatValue();
			count++;
		}

		if (count >= 4)
			return .(values[0], values[1], values[2], values[3]);
		return .((count > 0) ? values[0] : 0.0f);
	}

	/// A number, which a trailing percent sign divides by a hundred.
	public float ParseFloatValue()
	{
		if (Peek().Kind == .Number)
		{
			let token = Consume();
			var value = token.NumericValue;
			if (Peek().Kind == .Percent)
			{
				Consume();
				value /= 100.0f;
			}
			return value;
		}
		if (Peek().Kind == .Variable)
		{
			// A palette variable holds a colour, not a number.
			Consume();
			return 0.0f;
		}
		return 0.0f;
	}

	/// A drawable: a factory call, or a bare colour becoming a ColorDrawable.
	///
	/// The result is OWNED by the caller. Null when a factory could not build one.
	public Drawable ParseDrawableValue(StyleSheet sheet)
	{
		if (Peek().Kind == .Ident)
		{
			let factory = DrawableFactoryRegistry.Get(Peek().Text);
			if (factory != null)
			{
				// The function name.
				Consume();
				Expect(.LParen);
				let drawable = factory(this, sheet);
				Expect(.RParen);
				return drawable;
			}
		}
		return new ColorDrawable(ParseColorValue());
	}

	public bool MatchComma()
	{
		if (Peek().Kind == .Comma)
		{
			Consume();
			return true;
		}
		return false;
	}

	public bool IsAtRParen => Peek().Kind == .RParen;

	/// The name of a keyword argument, as in the `radius` of `radius=6`. Empty when the next
	/// tokens are not one.
	public StringView PeekKeywordArg()
	{
		if ((Peek().Kind == .Ident) && (mPos + 1 < (int32)mTokens.Count)
			&& (mTokens[mPos + 1].Kind == .Equals))
			return Peek().Text;
		return "";
	}

	public void ConsumeKeywordArg()
	{
		// The name, then the equals sign.
		Consume();
		Consume();
	}

	public StringView PeekIdent()
	{
		if (Peek().Kind == .Ident)
			return Peek().Text;
		return "";
	}

	public bool PeekIsNumber => Peek().Kind == .Number;

	/// A registered SVG's text, or null.
	public StringView? ResolveSvg(StringView name)
	{
		if (mSvgRegistry.TryGetValueAlt(name, let text))
			return StringView(text);
		return null;
	}

	/// A registered image, BORROWED, or null.
	public ImageData ResolveImage(StringView name)
	{
		if (mImageRegistry.TryGetValueAlt(name, let image))
			return image;
		return null;
	}

	public StringView ConsumeIdent()
	{
		if (Peek().Kind == .Ident)
			return Consume().Text;
		return "";
	}

	// ---- Directives ----------------------------------------------------------------------------

	private void ParseDirective()
	{
		let directive = Consume();
		switch (directive.Text)
		{
		case "@palette": ParsePaletteDirective();
		case "@icon": ParseIconDirective();
		case "@image": ParseImageDirective();
		case "@import": ParseImportDirective();
		default: SkipUntilSemicolon();
		}
	}

	private void ParsePaletteDirective()
	{
		// The palette's own name, kept for the multi palette support that has not arrived.
		ConsumeIdent();

		if (Peek().Kind == .Extends)
		{
			Consume();
			// The parent's name; the base palette is already loaded.
			ConsumeIdent();
		}

		Expect(.LBrace);
		while (!IsAtEnd && (Peek().Kind != .RBrace))
		{
			let name = ConsumeIdent();
			Expect(.Colon);
			let color = ParseColorValue();
			SetPaletteEntry(name, color);
			MatchSemicolon();
		}
		Expect(.RBrace);
	}

	private void SetPaletteEntry(StringView name, Color color)
	{
		if (mPalette.TryGetAlt(name, let existingKey, ?))
		{
			mPalette[existingKey] = color;
			return;
		}
		mPalette[new String(name)] = color;
	}

	private void ParseIconDirective()
	{
		let name = ConsumeIdent();
		let path = ConsumeString();
		MatchSemicolon();

		if ((mResourceProvider == null) || path.IsEmpty)
			return;

		let resolved = ResolvePath(path, .. scope String());
		let text = new String();
		if (!mResourceProvider.LoadText(resolved, text))
		{
			delete text;
			return;
		}

		if (mSvgRegistry.TryGetAlt(name, let existingKey, let existingText))
		{
			delete existingText;
			mSvgRegistry[existingKey] = text;
			return;
		}
		mSvgRegistry[new String(name)] = text;
	}

	private void ParseImageDirective()
	{
		let name = ConsumeIdent();
		let path = ConsumeString();
		MatchSemicolon();

		if ((mResourceProvider == null) || path.IsEmpty)
			return;

		let resolved = ResolvePath(path, .. scope String());
		let image = mResourceProvider.LoadImage(resolved);
		if (image == null)
			return;

		if (mImageRegistry.TryGetAlt(name, let existingKey, ?))
		{
			mImageRegistry[existingKey] = image;
			return;
		}
		mImageRegistry[new String(name)] = image;
	}

	private void ParseImportDirective()
	{
		let path = ConsumeString();
		MatchSemicolon();

		if ((mResourceProvider == null) || path.IsEmpty)
			return;

		let resolved = ResolvePath(path, .. scope String());
		let text = scope String();
		if (!mResourceProvider.LoadText(resolved, text))
			return;

		let tokenizer = scope Tokenizer(text);
		let tokens = new List<Token>();
		tokenizer.TokenizeAll(tokens);

		// The imported file's own base path, so ITS relative paths resolve against where it
		// lives rather than where the importer does.
		let importBase = scope String();
		var lastSlash = -1;
		for (int i < resolved.Length)
		{
			if ((resolved[i] == '/') || (resolved[i] == '\\'))
				lastSlash = i;
		}
		if (lastSlash >= 0)
			importBase.Set(StringView(resolved, 0, lastSlash + 1));

		// The palette and registries are SHARED, so an import can define colours the importer
		// then uses.
		let importParser = scope SSSParser(tokens, mPalette, mSvgRegistry, mImageRegistry,
			mResourceProvider, importBase);
		let importSheet = importParser.Parse();
		defer importSheet.ReleaseRef();
		mSheet.MergeFrom(importSheet);
	}

	// ---- Selectors -----------------------------------------------------------------------------

	/// Whether the current token TOUCHES the previous one, with no whitespace between.
	///
	/// The tokenizer drops whitespace, so the descendant combinator has to be recovered from
	/// token positions: `Panel .item` is a descendant selector where `Panel.item` is one
	/// compound.
	private bool TouchesPrevious()
	{
		if ((mPos <= 0) || (mPos >= (int32)mTokens.Count))
			return false;

		let previous = mTokens[mPos - 1];
		let current = mTokens[mPos];
		return (previous.Line == current.Line)
			&& (current.Column == previous.Column + (int32)previous.Text.Length);
	}

	private bool PeekStartsCompound()
	{
		switch (Peek().Kind)
		{
		case .Ident, .ClassSelector, .HexColor, .PseudoState:
			return true;
		default:
			return false;
		}
	}

	/// One compound of a selector chain. The pseudo element is read only for the SUBJECT, so
	/// `pseudo` is null for an ancestor step.
	private void ParseCompound(SelectorCompound compound, PseudoElementInfo pseudo)
	{
		// A type name no registry knows is CONSUMED and marks the compound as matching
		// nothing, rather than being mistaken for a property name.
		if (Peek().Kind == .Ident)
		{
			let typeName = Consume().Text;
			let type = UITypeRegistry.Resolve(typeName);
			if (type != null)
				compound.ViewType = type;
			else
				compound.UnknownType = true;
		}

		var consumedAny = (compound.ViewType != null) || compound.UnknownType;
		var state = ControlState.Normal;
		var hasState = false;

		for (;;)
		{
			// A part joins THIS compound when it touches the previous token or starts the
			// compound; whitespace before it is the descendant combinator, which the caller
			// handles.
			let joins = !consumedAny || TouchesPrevious();

			if ((Peek().Kind == .HexColor) && joins)
			{
				let token = Consume();
				// Past the leading hash.
				compound.SetId(token.Text.Substring(1));
				consumedAny = true;
				continue;
			}
			if ((Peek().Kind == .ClassSelector) && joins)
			{
				let token = Consume();
				compound.AddClass(token.Text.Substring(1));
				consumedAny = true;
				continue;
			}
			if ((Peek().Kind == .PseudoState) && joins)
			{
				consumedAny = true;
				let token = Consume();
				ApplyPseudoClass(token.Text.Substring(1), ref state, ref hasState, compound);
				continue;
			}
			break;
		}

		// A pseudo element. The tokenizer reads `::name` as a Colon followed by a PseudoState,
		// the second colon plus a letter looking exactly like one.
		if ((pseudo != null) && (Peek().Kind == .Colon) && (mPos + 1 < (int32)mTokens.Count)
			&& (mTokens[mPos + 1].Kind == .PseudoState))
		{
			Consume();
			let token = Consume();
			pseudo.Name.Set(token.Text.Substring(1));
			pseudo.Has = true;

			// A state may follow the pseudo element, as in `::tab:hover`.
			while (Peek().Kind == .PseudoState)
			{
				let stateToken = Consume();
				ApplyPseudoClass(stateToken.Text.Substring(1), ref pseudo.State,
					ref pseudo.HasState, compound);
			}
		}

		if (hasState)
			compound.State = state;
	}

	private void ParseRule()
	{
		let rule = new StyleRule();

		let compounds = scope List<SelectorCompound>();
		defer { ClearAndDeleteItems!(compounds); }
		/// Whether compound i is the DIRECT parent of i plus one.
		let childCombinator = scope List<bool>();
		let pseudo = scope PseudoElementInfo();

		for (;;)
		{
			let compound = new SelectorCompound();
			compounds.Add(compound);
			ParseCompound(compound, pseudo);

			// A pseudo element ends the chain, being the subject's.
			if (pseudo.Has)
				break;

			if (Peek().Kind == .Greater)
			{
				Consume();
				childCombinator.Add(true);
				continue;
			}
			if (PeekStartsCompound() && !TouchesPrevious())
			{
				childCombinator.Add(false);
				continue;
			}
			break;
		}

		// The LAST compound is the subject; the rest are ancestors.
		let subjectIndex = compounds.Count - 1;
		let subject = compounds[subjectIndex];

		rule.Selector.ViewType = subject.ViewType;
		rule.Selector.UnknownType = subject.UnknownType;
		for (let styleClass in subject.StyleClasses)
			rule.Selector.AddClass(styleClass);
		if (subject.Id != null)
			rule.Selector.SetId(subject.Id);
		rule.Selector.Structural = subject.Structural;

		if ((subject.State != null) || pseudo.HasState)
		{
			var state = (subject.State != null) ? subject.State.Value : ControlState.Normal;
			if (pseudo.HasState)
				state |= pseudo.State;
			rule.Selector.State = state;
		}
		if (pseudo.Has)
			rule.Selector.SetPseudoElement(pseudo.Name);

		// AddAncestor PREPENDS, so feeding outermost first leaves the list nearest first.
		for (int i < subjectIndex)
		{
			rule.Selector.AddAncestor(compounds[i], childCombinator[i]);
			// Ownership moved to the selector.
			compounds[i] = null;
		}

		Expect(.LBrace);
		while (!IsAtEnd && (Peek().Kind != .RBrace))
			ParseProperty(rule);
		Expect(.RBrace);

		mSheet.AddRule(rule);
	}

	// ---- Properties ----------------------------------------------------------------------------

	private void ParseProperty(StyleRule rule)
	{
		let propName = ConsumeIdent();
		Expect(.Colon);

		// `--name: value` is a custom property, typed by whatever literal follows.
		if ((propName.Length > 2) && (propName[0] == '-') && (propName[1] == '-'))
		{
			rule.SetCustom(propName, ParseCustomValue(rule));
			MatchSemicolon();
			return;
		}

		// `background-color` stores Background as a raw COLOUR, for controls that read it as
		// one; `background` always builds a drawable.
		if (propName == "background-color")
		{
			rule.Set(StyleProperty.Background, ParseColorValue());
			MatchSemicolon();
			return;
		}

		let resolved = ResolvePropertyName(propName);
		if (resolved == null)
		{
			SkipUntilSemicolonOrBrace();
			return;
		}
		let property = resolved.Value;

		// The cascade keywords and variable references apply to EVERY property.
		if (Peek().Kind == .Ident)
		{
			switch (Peek().Text)
			{
			case "inherit":
				Consume();
				rule.SetValue(property, .Inherit);
				MatchSemicolon();
				return;
			case "initial":
				Consume();
				rule.SetValue(property, .Initial);
				MatchSemicolon();
				return;
			case "var":
				rule.SetValue(property, ParseVarReference(property, rule));
				MatchSemicolon();
				return;
			default:
			}
		}

		if (IsStringProperty(property))
		{
			let text = ParseStringOrIdent();
			if (!text.IsEmpty)
				rule.Set(property, text);
			MatchSemicolon();
			return;
		}

		if (IsDrawableProperty(property))
		{
			let drawable = ParseDrawableValue(mSheet);
			if (drawable != null)
			{
				// The SHEET owns it; the rule's value borrows.
				mSheet.OwnDrawable(drawable);
				rule.Set(property, drawable);
			}
			MatchSemicolon();
			return;
		}

		let value = ParseStyleValue(property, rule);
		if (!value.IsNone)
			rule.SetValue(property, value);

		MatchSemicolon();
	}

	/// A property's typed value, or a keyword or var reference. Also used for a var fallback,
	/// which is written in the property's own syntax.
	private StyleValue ParseTypedValue(StyleProperty property, StyleRule rule)
	{
		// COUNT marks a custom property's fallback, typed by its literal.
		if (property == .COUNT)
			return ParseCustomValue(rule);

		if (Peek().Kind == .Ident)
		{
			switch (Peek().Text)
			{
			case "inherit":
				Consume();
				return .Inherit;
			case "initial":
				Consume();
				return .Initial;
			case "var":
				return ParseVarReference(property, rule);
			default:
			}
		}

		if (IsStringProperty(property))
		{
			let text = ParseStringOrIdent();
			return text.IsEmpty ? StyleValue.None : StyleValue.String(rule.OwnString(text));
		}

		if (IsDrawableProperty(property))
		{
			let drawable = ParseDrawableValue(mSheet);
			if (drawable == null)
				return .None;
			mSheet.OwnDrawable(drawable);
			return .Drawable(drawable);
		}

		return ParseStyleValue(property, rule);
	}

	/// `var(--name[, fallback])`, the fallback written in the property's own syntax.
	private StyleValue ParseVarReference(StyleProperty property, StyleRule rule)
	{
		Consume();
		Expect(.LParen);
		let name = ConsumeIdent();

		StyleValue fallback = .None;
		if (MatchComma())
			fallback = ParseTypedValue(property, rule);
		Expect(.RParen);

		let reference = new VariableReference(name);
		reference.Fallback = fallback;
		// The reference is a value payload, so the SHEET anchors it like a drawable.
		mSheet.OwnResource(reference);
		return .Variable(reference);
	}

	/// A custom property's value, typed by its literal.
	private StyleValue ParseCustomValue(StyleRule rule)
	{
		switch (Peek().Kind)
		{
		case .HexColor, .Variable:
			return .Color(ParseColorValue());
		case .Number:
			return ParseLengthOrFloat();
		case .StringLit:
			return .String(rule.OwnString(Consume().Text));
		case .BoolLit:
			return .Bool(Consume().Text == "true");
		case .Ident:
			let name = Peek().Text;
			if (name == "var")
				return ParseVarReference(.COUNT, rule);
			if (name == "calc")
				return ParseLengthOrFloat();
			if (DrawableFactoryRegistry.Get(name) != null)
			{
				let drawable = ParseDrawableValue(mSheet);
				if (drawable == null)
					return .None;
				mSheet.OwnDrawable(drawable);
				return .Drawable(drawable);
			}
			if ((StyleValueParser.ParseNamedColor(name) != null) || (name == "rgb")
				|| (name == "rgba") || IsColorFunctionName(name))
				return .Color(ParseColorValue());
			return .String(rule.OwnString(Consume().Text));
		default:
			SkipUntilSemicolonOrBrace();
			return .None;
		}
	}

	// ---- Lengths -------------------------------------------------------------------------------

	/// One length term: a number with an optional unit, or a trailing percent. A bare number
	/// and px, dp and pt are ABSOLUTE; em and percent are relative.
	private Unit ParseLengthTerm()
	{
		if (Peek().Kind != .Number)
			return Unit.Dp(0.0f);

		let token = Consume();
		if (Peek().Kind == .Percent)
		{
			Consume();
			return Unit.Percent(token.NumericValue);
		}
		return StyleValueParser.ParseUnit(token.NumericValue, token.UnitSuffix);
	}

	/// A number stays a Float unless it needs a reference to resolve, meaning em, a percent or
	/// a calc, in which case it becomes a Length.
	private StyleValue ParseLengthOrFloat()
	{
		if ((Peek().Kind == .Ident) && (Peek().Text == "calc"))
		{
			Consume();
			Expect(.LParen);
			var result = ParseLengthTerm();

			// One nesting level: a chain of added or subtracted terms. A `-20dp` written
			// without a space arrives as a NEGATIVE number and so adds.
			for (;;)
			{
				if (Peek().Kind == .Plus)
				{
					Consume();
					result = result + ParseLengthTerm();
				}
				else if (Peek().Kind == .Minus)
				{
					Consume();
					result = result - ParseLengthTerm();
				}
				else if (Peek().Kind == .Number)
				{
					result = result + ParseLengthTerm();
				}
				else
				{
					break;
				}
			}

			Expect(.RParen);
			return .Length(result);
		}

		if (Peek().Kind != .Number)
			return .None;

		let token = Peek();
		let percent = (mPos + 1 < (int32)mTokens.Count) && (mTokens[mPos + 1].Kind == .Percent);
		if (percent || (token.UnitSuffix == "em"))
			return .Length(ParseLengthTerm());
		return .Float(ParseFloatValue());
	}

	// ---- Typed values --------------------------------------------------------------------------

	private StyleValue ParseStyleValue(StyleProperty property, StyleRule rule)
	{
		if (IsColorProperty(property))
			return .Color(ParseColorValue());
		if (property == .BoxShadow)
			return ParseBoxShadowValue();
		if (property == .Transition)
			return ParseTransitionValue();

		if (IsSizeSpecProperty(property) && (Peek().Kind == .Ident) && (Peek().Text != "calc"))
		{
			// `match` and `wrap` travel as a String; the view's effective layout refresh maps
			// them onto the size spec kind.
			return .String(rule.OwnString(Consume().Text));
		}

		if (IsThicknessProperty(property))
			return .Thickness(ParseThicknessValue());

		if (IsBoolProperty(property))
		{
			if (Peek().Kind == .BoolLit)
				return .Bool(Consume().Text == "true");
			return .None;
		}

		return ParseLengthOrFloat();
	}

	/// `transition: none | <entry> {, <entry>}`, an entry being a property or `all`, a
	/// duration, and optionally an easing and a delay.
	///
	/// An unknown property name DROPS its entry, and `none` yields an EMPTY list, which is not
	/// the same as no list: it still overrides an inherited `all`.
	private StyleValue ParseTransitionValue()
	{
		let list = new TransitionList();
		mSheet.OwnResource(list);

		if ((Peek().Kind == .Ident) && (Peek().Text == "none"))
		{
			Consume();
			return .Transitions(list);
		}

		while (Peek().Kind == .Ident)
		{
			let name = Consume().Text;
			TransitionSpec spec = .();
			var known = true;

			if (name == "all")
			{
				spec.Property = .COUNT;
			}
			else
			{
				let resolved = ResolvePropertyName(name);
				if (resolved != null)
					spec.Property = resolved.Value;
				else
					known = false;
			}

			if (Peek().Kind == .Number)
				spec.Duration = ParseTimeSeconds();
			if (Peek().Kind == .Ident)
				spec.Easing = ParseEasingName(Consume().Text);
			if (Peek().Kind == .Number)
				spec.Delay = ParseTimeSeconds();

			if (known)
				list.Specs.Add(spec);
			if (!MatchComma())
				break;
		}

		return .Transitions(list);
	}

	/// A time in seconds. A bare number is MILLISECONDS, which is what a sheet usually means.
	private float ParseTimeSeconds()
	{
		let token = Consume();
		let value = Max(0.0f, token.NumericValue);
		if (token.UnitSuffix == "s")
			return value;
		return value / 1000.0f;
	}

	private static TransitionEasing ParseEasingName(StringView name)
	{
		switch (name)
		{
		case "linear": return .Linear;
		case "ease-in": return .EaseIn;
		case "ease-out": return .EaseOut;
		case "ease-in-out": return .EaseInOut;
		default: return .Ease;
		}
	}

	/// `box-shadow: <x> <y> [blur [spread]] <color> [inset]`, or `none`. The `inset` keyword
	/// may lead or trail.
	private StyleValue ParseBoxShadowValue()
	{
		if ((Peek().Kind == .Ident) && (Peek().Text == "none"))
		{
			Consume();
			return .None;
		}

		BoxShadow shadow = .();
		if ((Peek().Kind == .Ident) && (Peek().Text == "inset"))
		{
			Consume();
			shadow.Inset = true;
		}

		float[4] lengths = .();
		var count = 0;
		while ((count < 4) && (Peek().Kind == .Number))
		{
			lengths[count] = ParseFloatValue();
			count++;
		}

		// Without both offsets there is no shadow to describe.
		if (count < 2)
			return .None;

		shadow.OffsetX = lengths[0];
		shadow.OffsetY = lengths[1];
		shadow.Blur = (count > 2) ? Max(0.0f, lengths[2]) : 0.0f;
		shadow.Spread = (count > 3) ? lengths[3] : 0.0f;

		if ((Peek().Kind != .Semicolon) && (Peek().Kind != .RBrace)
			&& !((Peek().Kind == .Ident) && (Peek().Text == "inset")))
			shadow.Color = ParseColorValue();

		if ((Peek().Kind == .Ident) && (Peek().Text == "inset"))
		{
			Consume();
			shadow.Inset = true;
		}

		return .Shadow(shadow);
	}

	private Color ParseRgbFunction()
	{
		Consume();
		Expect(.LParen);

		let r = (int32)ParseFloatValue();
		MatchComma();
		let g = (int32)ParseFloatValue();
		MatchComma();
		let b = (int32)ParseFloatValue();

		// Per CSS, the channels are 0 to 255 but the alpha is 0 to 1.
		if (MatchComma())
		{
			let a = ParseFloatValue();
			Expect(.RParen);
			return .(r / 255.0f, g / 255.0f, b / 255.0f, a);
		}

		Expect(.RParen);
		return .(r / 255.0f, g / 255.0f, b / 255.0f, 1.0f);
	}

	private Color ParseColorFunction()
	{
		let name = ConsumeIdent();
		Expect(.LParen);
		var result = Color.White;

		switch (name)
		{
		case "lighten":
			let color = ParseColorValue();
			MatchComma();
			result = ColorFunctions.Lighten(color, ParseFloatValue());

		case "darken":
			let color = ParseColorValue();
			MatchComma();
			result = ColorFunctions.Darken(color, ParseFloatValue());

		case "alpha":
			let color = ParseColorValue();
			MatchComma();
			result = ColorFunctions.Alpha(color, ParseFloatValue());

		case "mix":
			let a = ParseColorValue();
			MatchComma();
			let b = ParseColorValue();
			MatchComma();
			result = ColorFunctions.Mix(a, b, ParseFloatValue());

		// The state derivations run the SAME arithmetic the themes use, so a sheet and a
		// hand built theme land on identical state colours. That matters most for disabled,
		// whose luminance desaturation lighten and darken cannot express.
		case "hover":
			result = Palette.ComputeHover(ParseColorValue());
		case "pressed":
			result = Palette.ComputePressed(ParseColorValue());
		case "disabled":
			result = Palette.ComputeDisabled(ParseColorValue());
		case "focused":
			// Not named `base`: that is a Beef keyword.
			let baseColor = ParseColorValue();
			MatchComma();
			result = Palette.ComputeFocused(baseColor, ParseColorValue());

		default:
		}

		Expect(.RParen);
		return result;
	}

	private Thickness ParseThicknessValue()
	{
		float[4] values = .();
		var count = 0;
		while ((count < 4) && (Peek().Kind == .Number))
		{
			values[count] = ParseFloatValue();
			count++;
		}
		return StyleValueParser.ParseThickness(Span<float>(&values[0], count));
	}

	// ---- Property names ------------------------------------------------------------------------

	/// The property a sheet's name refers to, or null when nothing does.
	public static StyleProperty? ResolvePropertyName(StringView name)
	{
		switch (name)
		{
		// Drawables.
		case "background": return .Background;
		case "checked-background": return .CheckedBackground;
		case "menu-item-hover-drawable": return .MenuItemHoverDrawable;

		// Colours.
		case "text-color": return .TextColor;
		case "text-dim-color": return .TextDimColor;
		case "placeholder-color": return .PlaceholderColor;
		case "border-color": return .BorderColor;
		case "cursor-color": return .CursorColor;
		case "selection-color": return .SelectionColor;
		case "accent-color": return .AccentColor;
		case "success-color": return .SuccessColor;
		case "warning-color": return .WarningColor;
		case "error-color": return .ErrorColor;

		// Numbers and the one string among them.
		case "font-size": return .FontSize;
		case "corner-radius": return .CornerRadius;
		case "font-family": return .FontFamily;
		case "border-width": return .BorderWidth;
		case "spacing": return .Spacing;
		case "opacity": return .Opacity;
		case "width": return .Width;
		case "height": return .Height;

		// Thicknesses.
		case "padding": return .Padding;
		case "margin": return .Margin;

		// Bools.
		case "word-wrap": return .WordWrap;

		// The box model.
		case "box-shadow": return .BoxShadow;
		case "min-width": return .MinWidth;
		case "min-height": return .MinHeight;
		case "max-width": return .MaxWidth;
		case "max-height": return .MaxHeight;
		case "top": return .Top;
		case "right": return .Right;
		case "bottom": return .Bottom;
		case "left": return .Left;
		case "z-index": return .ZIndex;
		case "flex-grow": return .FlexGrow;
		case "flex-shrink": return .FlexShrink;
		case "position": return .Position;
		case "overflow": return .Overflow;
		case "align-self": return .AlignSelf;

		// Transitions.
		case "transition": return .Transition;

		// Wrap, gap and ellipsis.
		case "flex-basis": return .FlexBasis;
		case "text-overflow": return .TextOverflow;

		default: return null;
		}
	}

	/// A pseudo class: a control state, with the CSS aliases, or a structural test. An unknown
	/// name is IGNORED rather than failing the selector.
	private static void ApplyPseudoClass(StringView name, ref ControlState state, ref bool hasState,
		SelectorCompound compound)
	{
		switch (name)
		{
		case "first-child":
			compound.Structural = compound.Structural | .FirstChild;
			return;
		case "last-child":
			compound.Structural = compound.Structural | .LastChild;
			return;
		case "empty":
			compound.Structural = compound.Structural | .Empty;
			return;
		default:
		}

		hasState = true;
		switch (name)
		{
		case "hover": state |= .Hover;
		case "pressed", "active": state |= .Pressed;
		case "focused", "focus", "focus-visible": state |= .Focused;
		case "disabled": state |= .Disabled;
		case "checked": state |= .Checked;
		case "indeterminate": state |= .Indeterminate;
		// `normal`, and anything unrecognised, adds no flag and so matches the normal state.
		default:
		}
	}

	// ---- Property kinds ------------------------------------------------------------------------
	// These are RANGE tests over the property order, which is why StyleProperty is appended to
	// rather than reordered.

	private static bool IsDrawableProperty(StyleProperty property) =>
		property <= .MenuItemHoverDrawable;

	private static bool IsColorProperty(StyleProperty property) =>
		(property >= .TextColor) && (property <= .ErrorColor);

	private static bool IsThicknessProperty(StyleProperty property) =>
		(property == .Padding) || (property == .Margin);

	private static bool IsBoolProperty(StyleProperty property) => property == .WordWrap;

	private static bool IsStringProperty(StyleProperty property)
	{
		switch (property)
		{
		case .FontFamily, .Position, .Overflow, .AlignSelf, .TextOverflow:
			return true;
		default:
			return false;
		}
	}

	/// Width and height take the size spec keywords as well as a length.
	private static bool IsSizeSpecProperty(StyleProperty property) =>
		(property == .Width) || (property == .Height);

	// ---- Helpers -------------------------------------------------------------------------------

	private StringView ParseStringOrIdent()
	{
		if ((Peek().Kind == .StringLit) || (Peek().Kind == .Ident))
			return Consume().Text;
		return "";
	}

	/// A palette variable's colour. An unresolved one is WHITE, so a sheet naming a colour
	/// that does not exist still loads.
	private Color ResolveVariable(StringView text)
	{
		let name = (!text.IsEmpty && (text[0] == '$')) ? text.Substring(1) : text;
		if (mPalette.TryGetValueAlt(name, let color))
			return color;
		return Color.White;
	}

	private void ResolvePath(StringView path, String outPath)
	{
		outPath.Clear();
		if (!mBasePath.IsEmpty)
			outPath.Append(mBasePath);
		outPath.Append(path);
	}

	// ---- Tokens --------------------------------------------------------------------------------

	private Token Peek() =>
		(mPos < (int32)mTokens.Count) ? mTokens[mPos] : Token(.EndOfInput, "", 0, 0);

	private Token Consume()
	{
		if (mPos >= (int32)mTokens.Count)
			return .(.EndOfInput, "", 0, 0);
		let token = mTokens[mPos];
		mPos++;
		return token;
	}

	private bool IsAtEnd =>
		(mPos >= (int32)mTokens.Count) || (mTokens[mPos].Kind == .EndOfInput);

	private StringView ConsumeString()
	{
		if (Peek().Kind == .StringLit)
			return Consume().Text;
		return "";
	}

	/// Consumes the token when it is the expected kind, and otherwise does NOTHING. The parser
	/// recovers rather than failing: a malformed sheet should still yield the rules around the
	/// mistake.
	private void Expect(TokenKind kind)
	{
		if (Peek().Kind == kind)
			Consume();
	}

	private bool MatchSemicolon()
	{
		if (Peek().Kind == .Semicolon)
		{
			Consume();
			return true;
		}
		return false;
	}

	private void SkipUntilSemicolon()
	{
		while (!IsAtEnd && (Peek().Kind != .Semicolon))
			Consume();
		MatchSemicolon();
	}

	/// Stops at a closing brace as well, so an unknown property cannot eat the rest of a rule.
	private void SkipUntilSemicolonOrBrace()
	{
		while (!IsAtEnd && (Peek().Kind != .Semicolon) && (Peek().Kind != .RBrace))
			Consume();
		MatchSemicolon();
	}
}
