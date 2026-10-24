using System;
using System.Collections;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// CSSParser: turns `.css` text into a StyleSheet. Ported from eepp's css/StyleSheetParser
// (common subset). Handles `/* comments */`, comma-separated selector lists, `name: value;`
// declaration blocks (custom properties and `!important` among them), `@media` blocks,
// `@keyframes`, `@font-face`, `@spritesheet` and `@import`; best-effort (malformed bits are
// skipped). Other at-rules are skipped, and nesting is not read. A quoted string is whole, as CSS
// tokenizes one: no `;`, brace or comment opener inside it ends or starts anything, and no `;`
// inside parentheses ends a declaration either (an inline SVG's markup,
// `url(data:...;base64,...)`). Given a diagnostics list, what it skips goes there with its line,
// for a cook: an at-rule it does not read, a declaration with no colon, text with no rule block, a
// rule not closed, a selector that can match nothing. Property names are checked apart
// (CheckStyleSheetNames: they depend on the element types registered).

static class CSSParser
{
	// The whole source (every block a part of it) and where its lines start.
	private class Source
	{
		public StringView Whole;
		public List<int> LineStarts = new .() ~ delete _;
		/// Where what is skipped is said (borrowed; null: nowhere).
		public List<GuiDiagnostic> Diagnostics = null;

		// Says what was skipped at `part` (its line), when diagnostics were asked for.
		public void Skipped(StringView part, StringView message)
		{
			if (Diagnostics == null)
				return;
			let d = new GuiDiagnostic();
			d.Level = .Warning;
			d.Line = LineOf(part);
			d.Message.Set(message);
			Diagnostics.Add(d);
		}

		// The 1-based line of `part`'s first character other than white space.
		public uint32 LineOf(StringView part)
		{
			var at = (int)(part.Ptr - Whole.Ptr);
			for (int k = 0; (k < part.Length) && ParseUtil.IsWhiteSpace(part[k]); k++)
				at++;
			int lo = 0;
			int hi = LineStarts.Count;
			while (hi - lo > 1)
			{
				let mid = (lo + hi) / 2;
				if (LineStarts[mid] <= at)
					lo = mid;
				else
					hi = mid;
			}
			return (uint32)(lo + 1);
		}
	}

	/// Parses CSS source into `outSheet` (its rules after any it has).
	public static void Parse(StringView css, StyleSheet outSheet)
	{
		Parse(css, default, null, outSheet);
	}

	/// Parses CSS source into `outSheet`, naming it `name` (a path, "theme": where its rules came
	/// from, which each rule keeps with its line and selector, for the inspector).
	public static void Parse(StringView css, StringView name, StyleSheet outSheet)
	{
		Parse(css, name, null, outSheet);
	}

	/// As Parse; given `diagnostics`, what it skips is said there (the caller owns the list and
	/// what is added to it).
	public static void Parse(StringView css, StringView name, List<GuiDiagnostic> diagnostics, StyleSheet outSheet)
	{
		let cleaned = scope String();
		CSSParserDetail.StripComments(css, cleaned);
		outSheet.Name = name;
		let source = scope Source();
		source.Whole = cleaned;
		source.Diagnostics = diagnostics;
		source.LineStarts.Add(0);
		for (int i = 0; i < cleaned.Length; i++)
		{
			if (cleaned[i] == '\n')
				source.LineStarts.Add(i + 1);
		}
		let media = scope MediaQuery();
		ParseBlock(outSheet, source, cleaned, media);
	}

	// Parse a run of rules (and nested @media blocks), attaching `media` to each rule.
	private static void ParseBlock(StyleSheet sheet, Source source, StringView src, MediaQuery media)
	{
		let n = src.Length;
		int i = 0;
		let message = scope String();
		while (i < n)
		{
			while ((i < n) && ParseUtil.IsWhiteSpace(src[i]))
				i++;
			if (i >= n)
				break;

			if (src[i] == '@')
			{
				// At-rule: read the prelude up to '{' (block) or ';' (statement).
				let atStart = i;
				i = CSSParserDetail.ScanTo(src, i, "{;");
				let prelude = ParseUtil.Trim(src.Substring(atStart, i - atStart));
				if ((i < n) && (src[i] == ';'))
				{
					i++;
					// @import url(path) or "path": the style manager loads it through its resource
					// provider. Other at-statements are skipped.
					bool read = false;
					if ((prelude.Length > 7) && (prelude.Substring(0, 7) == "@import"))
					{
						let path = ImportPath(prelude.Substring(7, prelude.Length - 7));
						if (path.Length != 0)
						{
							sheet.AddImport(path);
							read = true;
						}
					}
					if (!read)
						source.Skipped(prelude, message..Clear()..AppendF("an at-rule it does not read: {}", prelude));
					continue;
				}
				if (i >= n)
					break;

				// Brace-matched block for this at-rule.
				i++; // consume '{'
				let atBlockStart = i;
				int32 depth = 1;
				while ((i < n) && (depth > 0))
				{
					let past = CSSParserDetail.SkipQuoted(src, i);
					if (past != i)
					{
						i = past;
						continue;
					}
					if (src[i] == '{')
						depth++;
					else if (src[i] == '}')
					{
						depth--;
						if (depth == 0)
							break;
					}
					i++;
				}
				let inner = src.Substring(atBlockStart, i - atBlockStart);
				if (i < n)
					i++; // consume '}'

				if (IsMedia(prelude))
				{
					let condition = ParseUtil.Trim(prelude.Substring(6, prelude.Length - 6));
					let innerMedia = scope MediaQuery(condition);
					ParseBlock(sheet, source, inner, innerMedia); // v1: inner media replaces outer
				}
				else if (IsKeyframes(prelude))
				{
					ParseKeyframes(source, sheet, ParseUtil.Trim(prelude.Substring(10, prelude.Length - 10)), inner); // after "@keyframes"
				}
				else if (prelude == "@font-face")
				{
					ParseFontFace(source, sheet, inner);
				}
				else if ((prelude.Length > 13) && (prelude.Substring(0, 13) == "@spritesheet "))
				{
					ParseSpritesheet(source, sheet, ParseUtil.Trim(prelude.Substring(13, prelude.Length - 13)), inner);
				}
				else // unknown at-rule blocks are consumed and skipped
					source.Skipped(prelude, message..Clear()..AppendF("an at-rule it does not read: {}", prelude));
				continue;
			}

			// Normal rule: selector list up to '{'.
			let selStart = i;
			i = CSSParserDetail.ScanTo(src, i, "{}");
			if ((i >= n) || (src[i] != '{'))
			{
				let stray = ParseUtil.Trim(src.Substring(selStart, i - selStart));
				source.Skipped(src.Substring(selStart, i - selStart), message..Clear()..AppendF("text with no rule block: {}", stray));
				break;
			}
			let selectorList = src.Substring(selStart, i - selStart);
			i++; // consume '{'

			let blockStart = i;
			i = CSSParserDetail.ScanTo(src, i, "}");
			let block = src.Substring(blockStart, i - blockStart);
			if (i < n)
				i++; // consume '}'
			else
				source.Skipped(selectorList, message..Clear()..AppendF("the rule for {} is not closed", ParseUtil.Trim(selectorList)));

			EmitRules(source, sheet, source.LineOf(selectorList), selectorList, block, media);
		}
	}

	// An @spritesheet's block: `src: url(atlas.png);` and a `name: x y width height;` per sprite,
	// in the image's pixels (px or none). One without a source is dropped.
	private static void ParseSpritesheet(Source source, StyleSheet sheet, StringView name, StringView block)
	{
		let output = new Spritesheet();
		output.Name.Set(name);
		let declarations = scope List<StyleProperty>();
		defer { ClearAndDeleteItems!(declarations); }
		ParseDeclList(source, block, declarations);
		for (let p in declarations)
		{
			let value = ParseUtil.Trim(p.Value);
			if (p.Name == "src")
			{
				var path = value;
				if ((path.Length > 5) && (path.Substring(0, 4) == "url(") && (path[path.Length - 1] == ')'))
					path = ParseUtil.Trim(path.Substring(4, path.Length - 5));
				if ((path.Length >= 2) && ((path[0] == '"') || (path[0] == '\'')) && (path[path.Length - 1] == path[0]))
					path = path.Substring(1, path.Length - 2);
				output.Source.Set(path);
				continue;
			}
			float[4] v = default;
			int count = 0;
			int start = 0;
			for (int i = 0; (i <= value.Length) && (count < 4); i++)
			{
				if ((i == value.Length) || (value[i] == ' '))
				{
					var token = value.Substring(start, i - start);
					if ((token.Length > 2) && (token.Substring(token.Length - 2, 2) == "px"))
						token = token.Substring(0, token.Length - 2);
					let number = ParseLength(token);
					if ((token.Length != 0) && number.HasValue)
						v[count++] = number.Value;
					start = i + 1;
				}
			}
			if (count == 4)
				output.Sprites.Add(new Sprite(p.Name, v[0], v[1], v[2], v[3]));
		}
		if (output.Source.Length != 0)
			sheet.AddSpritesheet(output);
		else
			delete output;
	}

	// An @import's path: its url() or its quoted string (a media list after it is ignored).
	private static StringView ImportPath(StringView rest)
	{
		var s = ParseUtil.Trim(rest);
		if ((s.Length > 5) && (s.Substring(0, 4) == "url("))
		{
			int close = 4;
			while ((close < s.Length) && (s[close] != ')'))
				close++;
			s = ParseUtil.Trim(s.Substring(4, close - 4));
		}
		else if ((s.Length != 0) && ((s[0] == '"') || (s[0] == '\'')))
		{
			int close = 1;
			while ((close < s.Length) && (s[close] != s[0]))
				close++;
			return s.Substring(1, close - 1);
		}
		if ((s.Length >= 2) && ((s[0] == '"') || (s[0] == '\'')) && (s[s.Length - 1] == s[0]))
			s = s.Substring(1, s.Length - 2);
		return s;
	}

	private static bool IsMedia(StringView prelude) => (prelude.Length >= 6) && (prelude.Substring(0, 6) == "@media");

	private static bool IsKeyframes(StringView prelude) => (prelude.Length >= 10) && (prelude.Substring(0, 10) == "@keyframes");

	// An @font-face's declarations: font-family and src (its first url, a path), font-weight (a
	// number, normal or bold) and font-style; one without a family or a source is dropped.
	private static void ParseFontFace(Source source, StyleSheet sheet, StringView block)
	{
		let face = new FontFaceRule();
		let declarations = scope List<StyleProperty>();
		defer { ClearAndDeleteItems!(declarations); }
		ParseDeclList(source, block, declarations);
		for (let p in declarations)
		{
			let value = ParseUtil.Trim(p.Value);
			if (p.Name == "font-family")
			{
				var family = value;
				if ((family.Length >= 2) && ((family[0] == '"') || (family[0] == '\'')) && (family[family.Length - 1] == family[0]))
					family = ParseUtil.Trim(family.Substring(1, family.Length - 2));
				face.Family.Set(family);
			}
			else if (p.Name == "src")
			{
				// The first source of a list (`url(a.ttf) format("truetype"), url(b.woff)`).
				int end = 0;
				while ((end < value.Length) && (value[end] != ')') && (value[end] != ','))
					end++;
				var first = ParseUtil.Trim(value.Substring(0, ((end < value.Length) && (value[end] == ')')) ? end + 1 : end));
				if ((first.Length >= 5) && (first.Substring(0, 4) == "url(") && (first[first.Length - 1] == ')'))
					first = ParseUtil.Trim(first.Substring(4, first.Length - 5));
				if ((first.Length >= 2) && ((first[0] == '"') || (first[0] == '\'')) && (first[first.Length - 1] == first[0]))
					first = first.Substring(1, first.Length - 2);
				face.Source.Set(first);
			}
			else if (p.Name == "font-weight")
			{
				if (value == "bold")
					face.Weight = 700;
				else
				{
					let w = TextRunsDetail.ParseFloat(value);
					if (w.HasValue && (w.Value >= 1.0) && (w.Value <= 1000.0))
						face.Weight = (uint16)w.Value;
				}
			}
			else if (p.Name == "font-style")
			{
				face.Italic = (value == "italic") || value.StartsWith("oblique");
			}
		}
		if ((face.Family.Length != 0) && (face.Source.Length != 0))
			sheet.AddFontFace(face);
		else
			delete face;
	}

	// Parse the inner of @keyframes: a run of `<offset-list> { decls }` stops (offset is a
	// percentage, or from/to). Comma-separated offsets share a block.
	private static void ParseKeyframes(Source source, StyleSheet sheet, StringView name, StringView inner)
	{
		let keyframes = new Keyframes();
		keyframes.Name.Set(name);

		let n = inner.Length;
		int i = 0;
		while (i < n)
		{
			while ((i < n) && ParseUtil.IsWhiteSpace(inner[i]))
				i++;
			if (i >= n)
				break;

			let selStart = i;
			i = CSSParserDetail.ScanTo(inner, i, "{");
			if (i >= n)
				break;
			let offsetList = inner.Substring(selStart, i - selStart);
			i++; // consume '{'
			let blockStart = i;
			i = CSSParserDetail.ScanTo(inner, i, "}");
			let block = inner.Substring(blockStart, i - blockStart);
			if (i < n)
				i++; // consume '}'

			// A stop per (comma-separated) offset, sharing the declarations.
			int s = 0;
			let on = offsetList.Length;
			for (int k = 0; k <= on; k++)
			{
				if ((k == on) || (offsetList[k] == ','))
				{
					let spec = ParseUtil.Trim(offsetList.Substring(s, k - s));
					if (ParseKeyframeOffset(spec, let offset))
					{
						let stop = new KeyframeStop();
						stop.Offset = offset;
						ParseDeclList(source, block, stop.Properties);
						keyframes.Stops.Add(stop);
					}
					s = k + 1;
				}
			}
		}
		sheet.AddKeyframes(keyframes);
	}

	// "0%".."100%" -> 0..1; "from" -> 0; "to" -> 1. Returns false if unrecognized.
	private static bool ParseKeyframeOffset(StringView spec, out float outOffset)
	{
		outOffset = 0.0f;
		if (spec == "from")
		{
			outOffset = 0.0f;
			return true;
		}
		if (spec == "to")
		{
			outOffset = 1.0f;
			return true;
		}
		var len = spec.Length;
		if (len == 0)
			return false;
		if (spec[len - 1] == '%')
			len--; // strip trailing %
		float value = 0.0f;
		float scale = 1.0f;
		bool seenDot = false;
		bool any = false;
		for (int k = 0; k < len; k++)
		{
			let c = spec[k];
			if (c == '.')
			{
				seenDot = true;
				continue;
			}
			if ((c < '0') || (c > '9'))
				return false;
			any = true;
			let digit = (float)((int32)c - (int32)'0');
			if (seenDot)
			{
				scale *= 0.1f;
				value += digit * scale;
			}
			else
				value = value * 10.0f + digit;
		}
		if (!any)
			return false;
		outOffset = value * 0.01f; // percent -> fraction
		return true;
	}

	// One rule per comma-separated selector, each carrying the block's declarations + media.
	private static void EmitRules(Source source, StyleSheet sheet, uint32 line, StringView selectorList, StringView block, MediaQuery media)
	{
		// Commas inside :is(), :not() or [a="b,c"] do not split.
		let selectors = scope List<StringView>();
		StyleSelector.SplitList(selectorList, selectors);
		for (let selector in selectors)
		{
			let rule = new StyleRule(selector);
			rule.SetSource(ParseUtil.Trim(selector), line);
			if (rule.Selector.IsNever)
			{
				source.Skipped(selectorList, scope String()..AppendF(
					"the selector {} matches nothing (a pseudo-class or function it does not know, or a typo)", ParseUtil.Trim(selector)));
			}
			ApplyDeclarations(source, rule, block);
			if (!media.IsEmpty)
				rule.Media = media;
			sheet.AddRule(rule);
		}
	}

	// Split `name: value;` declarations into the rule (later same-name wins via SetProperty).
	private static void ApplyDeclarations(Source source, StyleRule rule, StringView block)
	{
		let declarations = scope List<StyleProperty>();
		defer { ClearAndDeleteItems!(declarations); }
		ParseDeclList(source, block, declarations);
		for (let p in declarations)
			rule.SetProperty(p.Name, p.Value, p.Important);
	}

	// Parse `name: value;` declarations into a flat property list (in source order), added to
	// `outProperties`, which owns them.
	private static void ParseDeclList(Source source, StringView block, List<StyleProperty> outProperties)
	{
		int start = 0;
		let n = block.Length;
		while (start <= n)
		{
			let end = CSSParserDetail.ScanTo(block, start, ";");
			let decl = block.Substring(start, end - start);
			start = end + 1;
			let colon = FindChar(decl, ':');
			if (colon == cNotFound)
			{
				if (ParseUtil.Trim(decl).Length != 0)
					source.Skipped(decl, scope String()..AppendF("a declaration with no colon: {}", ParseUtil.Trim(decl)));
				continue;
			}
			let name = ParseUtil.Trim(decl.Substring(0, colon));
			var value = ParseUtil.Trim(decl.Substring(colon + 1, decl.Length - colon - 1));

			// Trailing !important.
			bool important = false;
			StringView flag = "!important";
			if ((value.Length >= flag.Length) && (value.Substring(value.Length - flag.Length, flag.Length) == flag))
			{
				important = true;
				value = ParseUtil.Trim(value.Substring(0, value.Length - flag.Length));
			}

			if (name.Length != 0)
				outProperties.Add(new StyleProperty(name, value, important));
		}
	}

	private const int cNotFound = -1;

	private static int FindChar(StringView s, char8 c)
	{
		for (int i = 0; i < s.Length; i++)
		{
			if (s[i] == c)
				return i;
		}
		return cNotFound;
	}
}

/// What CSSParser.bf keeps out of the public surface: the scanning its parts share.
internal static class CSSParserDetail
{
	// Past the quoted string starting at `i` (its closing quote, a backslash escaping one), or
	// `i` when no string starts there.
	public static int SkipQuoted(StringView s, int i)
	{
		var i;
		if ((i >= s.Length) || ((s[i] != '"') && (s[i] != '\'')))
			return i;
		let quote = s[i++];
		while ((i < s.Length) && (s[i] != quote))
			i += ((s[i] == '\\') && (i + 1 < s.Length)) ? 2 : 1;
		return (i < s.Length) ? i + 1 : i;
	}

	// The first of `stops` from `i` outside quoted strings and parentheses; the end when none.
	public static int ScanTo(StringView s, int i, StringView stops)
	{
		var i;
		int depth = 0;
		while (i < s.Length)
		{
			let past = SkipQuoted(s, i);
			if (past != i)
			{
				i = past;
				continue;
			}
			let c = s[i];
			if (depth == 0)
			{
				for (let stop in stops)
				{
					if (c == stop)
						return i;
				}
			}
			if (c == '(')
				depth++;
			else if ((c == ')') && (depth > 0))
				depth--;
			i++;
		}
		return i;
	}

	// Blank out /* ... */ comments, keeping their line breaks, so a rule's place in the result is
	// its place in the source (its line, for the inspector). Appended to `outText`.
	public static void StripComments(StringView s, String outText)
	{
		let n = s.Length;
		int runStart = 0;
		int i = 0;
		while (i < n)
		{
			let past = SkipQuoted(s, i);
			if (past != i)
				i = past; // a string's "/*" is its text
			else if ((i + 1 < n) && (s[i] == '/') && (s[i + 1] == '*'))
			{
				outText.Append(s.Substring(runStart, i - runStart));
				let start = i;
				i += 2;
				while ((i + 1 < n) && !((s[i] == '*') && (s[i + 1] == '/')))
					i++;
				i = (i + 1 < n) ? i + 2 : n; // skip closing */ (or to end)
				for (int k = start; k < i; k++)
					outText.Append((s[k] == '\n') ? '\n' : ' ');
				runStart = i;
			}
			else
			{
				i++;
			}
		}
		outText.Append(s.Substring(runStart, n - runStart));
	}
}
