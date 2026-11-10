using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// A language's definition: a value its owners supply, built in code or read from a file through
// the engine's serialization (the editor's and the sandbox's, Data/Editor/Code); the
// library ships none. A definition is contexts, each a list of rules tried in turn at each place of
// a line: a literal, an identifier (looked up in the language's words: keywords, types, constants),
// a number, one of some characters or a run of them, the rest of the line, and a long bracket's
// open or close (Luau's `[==[`). A rule gives its text a token, and may enter a context (a string, a
// comment, a tag) or leave some; what no rule takes is its context's token, an escape character
// taking the next with it. A context may end at the line's end (a line comment, a preprocessor
// line).
//
// The tokenizer reads one line at a time from the state the line before ended in (the contexts
// entered, a long bracket's level), as every editor surveyed does; a view keeps each line's tokens
// with the state it began in and the line's hash, and stops tokenizing where a line ends in the
// state it ended in before (eepp's).

/// What a run of code is: each draws in its part's colour (`codeeditor::keyword`).
enum CodeToken : uint8
{
	Text,
	Keyword,
	Type,
	Constant,
	Builtin,
	Number,
	String,
	Escape,
	Comment,
	Preprocessor,
	Operator,
	Punctuation,
	Tag,
	Attribute,
	Property,
	Selector,
	Invalid,
	Count,
}

static
{
	/// A token's name: its part's (`keyword`), and how a definition file writes it.
	public static StringView CodeTokenName(CodeToken token)
	{
		return (token < .Count) ? (StringView)CodeLanguageDetail.sCodeTokenNames[(int)token] : "text";
	}

	public static CodeToken CodeTokenNamed(StringView name)
	{
		for (int i < (int)CodeToken.Count)
		{
			if (name == CodeLanguageDetail.sCodeTokenNames[i])
				return (CodeToken)i;
		}
		return .Text;
	}
}

/// What a rule matches at a place in a line.
enum CodeMatch : uint8
{
	/// Its text, as it is.
	Literal,
	/// A name (letters, digits, underscores; not first a digit), looked up in the words.
	Identifier,
	/// A number: decimal, 0x hex, 0b binary, 0o octal, with a fraction, an exponent, a suffix, and
	/// the language's digit separators between its digits.
	Number,
	/// One of its text's characters.
	AnyOf,
	/// One or more of its text's characters (a CSS colour's `#1a2b3c`).
	Run,
	/// The rest of the line.
	LineRest,
	/// Its text's character, '='s, the character again (Luau's `[==[`), the '='s kept.
	LongOpen,
	/// Its text's character, as many '='s as the open's, the character again.
	LongClose,
}

/// A rule of a context. A class: it owns its text; Set copies another deeply.
class CodeRule : ISerializable
{
	public CodeMatch Match = .Literal;
	/// The literal; the characters of any-of; a long bracket's character.
	public String Text = new .() ~ delete _;
	/// An identifier's when the words do not name it.
	public CodeToken Token = .Text;
	/// The context it enters, by name (empty: none).
	public String Enter = new .() ~ delete _;
	/// How many contexts it leaves (before entering).
	public uint8 Leave = 0;
	/// Only first on its line, past the indent (a `#` line).
	public bool LineStart = false;

	/// Makes this a copy of `other`.
	public void Set(CodeRule other)
	{
		if (other === this)
			return;
		Match = other.Match;
		Text.Set(other.Text);
		Token = other.Token;
		Enter.Set(other.Enter);
		Leave = other.Leave;
		LineStart = other.LineStart;
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		let match = scope String(CodeLanguageDetail.sCodeMatchNames[(int)Match]);
		CodeLanguageDetail.Optional(ar, "match", match);
		for (int i < CodeLanguageDetail.sCodeMatchNames.Count)
		{
			if (match == CodeLanguageDetail.sCodeMatchNames[i])
				Match = (CodeMatch)i;
		}
		CodeLanguageDetail.Optional(ar, "text", Text);
		CodeLanguageDetail.TokenField(ar, "token", ref Token);
		CodeLanguageDetail.Optional(ar, "enter", Enter);
		CodeLanguageDetail.Optional(ar, "leave", ref Leave);
		CodeLanguageDetail.Optional(ar, "lineStart", ref LineStart);
		ar.EndObject();
	}
}

/// A context: its rules, its token, its escape. A class: it owns its rules; Set copies another
/// deeply.
class CodeContext : ISerializable
{
	public String Name = new .() ~ delete _;
	/// What no rule takes is.
	public CodeToken Token = .Text;
	/// An escape: it and the character after it, escape tokens.
	public String Escape = new .() ~ delete _;
	/// Left where its line ends.
	public bool EndsAtLineEnd = false;
	public List<CodeRule> Rules = new .() ~ DeleteContainerAndItems!(_);

	/// Makes this a copy of `other`.
	public void Set(CodeContext other)
	{
		if (other === this)
			return;
		Name.Set(other.Name);
		Token = other.Token;
		Escape.Set(other.Escape);
		EndsAtLineEnd = other.EndsAtLineEnd;
		ClearAndDeleteItems!(Rules);
		for (let rule in other.Rules)
		{
			let copy = new CodeRule();
			copy.Set(rule);
			Rules.Add(copy);
		}
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		CodeLanguageDetail.Optional(ar, "name", Name);
		CodeLanguageDetail.TokenField(ar, "token", ref Token);
		CodeLanguageDetail.Optional(ar, "escape", Escape);
		CodeLanguageDetail.Optional(ar, "endsAtLineEnd", ref EndsAtLineEnd);
		CodeLanguageDetail.Optional(ar, "rules", Rules);
		ar.EndObject();
	}
}

/// Words a language names, of one token: its keywords, its types, its constants (`List` the words,
/// space-separated). A class: it owns its list; Set copies another.
class CodeWords : ISerializable
{
	public CodeToken Token = .Keyword;
	public String List = new .() ~ delete _;

	public this() { }

	public this(CodeToken token, StringView list)
	{
		Token = token;
		List.Set(list);
	}

	/// Makes this a copy of `other`.
	public void Set(CodeWords other)
	{
		if (other === this)
			return;
		Token = other.Token;
		List.Set(other.List);
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		CodeLanguageDetail.TokenField(ar, "token", ref Token);
		CodeLanguageDetail.Optional(ar, "list", List);
		ar.EndObject();
	}
}

/// A pair the editor knows: a bracket it matches, or what typing one side puts the other for. A
/// class: it owns its texts; Set copies another.
class CodePair : ISerializable
{
	public String Open = new .() ~ delete _;
	public String Close = new .() ~ delete _;

	public this() { }

	public this(StringView open, StringView close)
	{
		Open.Set(open);
		Close.Set(close);
	}

	/// Makes this a copy of `other`.
	public void Set(CodePair other)
	{
		if (other === this)
			return;
		Open.Set(other.Open);
		Close.Set(other.Close);
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		CodeLanguageDetail.Optional(ar, "open", Open);
		CodeLanguageDetail.Optional(ar, "close", Close);
		ar.EndObject();
	}
}

/// Where a line's tokenizing stands: the contexts entered (the first context below them all) and an
/// open long bracket's level.
struct CodeLexState : IEquatable<CodeLexState>
{
	public const uint8 cDepth = 7;
	public uint8 Depth = 0;
	public uint8[cDepth] Stack = default;
	public uint8 Level = 0;

	public this() { }

	public uint8 Top => (Depth > 0) ? Stack[Depth - 1] : 0;

	public bool Equals(CodeLexState other) => this == other;

	[Commutable]
	public static bool operator==(CodeLexState a, CodeLexState o)
	{
		if ((a.Depth != o.Depth) || (a.Level != o.Level))
			return false;
		for (uint8 i = 0; i < a.Depth; ++i)
		{
			if (a.Stack[i] != o.Stack[i])
				return false;
		}
		return true;
	}
}

/// A run of a line's bytes and its token.
struct CodeSpan
{
	public uint32 Start = 0;
	public uint32 End = 0;
	public CodeToken Token = .Text;

	public this() { }

	public this(uint32 start, uint32 end, CodeToken token)
	{
		Start = start;
		End = end;
		Token = token;
	}
}

/// A language's definition. A class: it owns its lists; Set copies another deeply (Prepared again
/// when the other was).
class CodeLanguage : ISerializable
{
	/// What its owners register it by ("beef").
	public String Id = new .() ~ delete _;
	/// What it is called ("Beef").
	public String Name = new .() ~ delete _;
	/// File name endings it is for ("bf").
	public List<String> Extensions = new .() ~ DeleteContainerAndItems!(_);
	/// Names may hold '-' and begin with it (CSS's).
	public bool IdentifierDashes = false;
	/// What may stand between a number's digits besides '_' (Beef's `1'000'000`, `0xFFFF'FFFF`):
	/// taken only where a digit follows, so a character literal after a number stays one.
	public String DigitSeparators = new .() ~ delete _;
	public List<CodeWords> Words = new .() ~ DeleteContainerAndItems!(_);
	/// The first is where a file starts.
	public List<CodeContext> Contexts = new .() ~ DeleteContainerAndItems!(_);
	// How it is edited:
	/// What a line comment begins with ("//", "--").
	public String LineComment = new .() ~ delete _;
	/// A block comment's ends ("/*" "*/", "<!--" "-->").
	public CodePair BlockComment = new .() ~ delete _;
	/// Matched, and indent between ("(" ")", "{" "}").
	public List<CodePair> Brackets = new .() ~ DeleteContainerAndItems!(_);
	/// Typing the open puts the close ("(" ")", "\"" "\"").
	public List<CodePair> AutoClose = new .() ~ DeleteContainerAndItems!(_);
	/// What, ending a line, indents the next (space-separated: "{ ( [", Luau's "then do").
	public String IndentAfter = new .() ~ delete _;
	/// What, first on its line, outdents it ("}", Luau's "end else until").
	public String OutdentFirst = new .() ~ delete _;
	// How it folds:
	/// By indentation rather than by its brackets (Luau's blocks, markup).
	public bool FoldByIndent = false;
	/// A line beginning with it opens a fold to its RegionEnd ("#pragma region").
	public String RegionStart = new .() ~ delete _;
	public String RegionEnd = new .() ~ delete _;

	// Each rule's context to enter, in context order.
	private List<int32> mEnter = new .() ~ delete _;
	private Dictionary<String, CodeToken> mWords = new .() ~ DeleteDictionaryAndKeys!(_);
	private bool mPrepared = false;

	/// Makes this a copy of `other`.
	public void Set(CodeLanguage other)
	{
		if (other === this)
			return;
		Id.Set(other.Id);
		Name.Set(other.Name);
		ClearAndDeleteItems!(Extensions);
		for (let @extension in other.Extensions)
			Extensions.Add(new String(@extension));
		IdentifierDashes = other.IdentifierDashes;
		DigitSeparators.Set(other.DigitSeparators);
		ClearAndDeleteItems!(Words);
		for (let words in other.Words)
		{
			let copy = new CodeWords();
			copy.Set(words);
			Words.Add(copy);
		}
		ClearAndDeleteItems!(Contexts);
		for (let context in other.Contexts)
		{
			let copy = new CodeContext();
			copy.Set(context);
			Contexts.Add(copy);
		}
		LineComment.Set(other.LineComment);
		BlockComment.Set(other.BlockComment);
		CodeLanguageDetail.CopyPairs(other.Brackets, Brackets);
		CodeLanguageDetail.CopyPairs(other.AutoClose, AutoClose);
		IndentAfter.Set(other.IndentAfter);
		OutdentFirst.Set(other.OutdentFirst);
		FoldByIndent = other.FoldByIndent;
		RegionStart.Set(other.RegionStart);
		RegionEnd.Set(other.RegionEnd);
		mEnter.Clear();
		for (let words in mWords)
			delete words.key;
		mWords.Clear();
		mPrepared = false;
		if (other.mPrepared)
			Prepare();
	}

	/// Resolves what refers by name (a rule's context, the words), once after it is filled in or
	/// read; tokenizing asks it first.
	public void Prepare()
	{
		mEnter.Clear();
		for (let context in Contexts)
		{
			for (let rule in context.Rules)
			{
				int32 index = -1;
				if (!rule.Enter.IsEmpty)
				{
					for (int i < Contexts.Count)
					{
						if (Contexts[i].Name == rule.Enter)
							index = (int32)i;
					}
				}
				mEnter.Add(index);
			}
		}
		for (let words in mWords)
			delete words.key;
		mWords.Clear();
		for (let group in Words)
		{
			StringView list = group.List;
			int at = 0;
			while (at < list.Length)
			{
				while ((at < list.Length) && ((list[at] == ' ') || (list[at] == '\n') || (list[at] == '\t') || (list[at] == '\r')))
					++at;
				int end = at;
				while ((end < list.Length) && (list[end] != ' ') && (list[end] != '\n') && (list[end] != '\t') && (list[end] != '\r'))
					++end;
				if (end > at)
				{
					let word = list.Substring(at, end - at);
					if (mWords.TryAddAlt(word, let keyPtr, let valuePtr))
						*keyPtr = new String(word);
					*valuePtr = group.Token;
				}
				at = end;
			}
		}
		mPrepared = true;
	}

	/// Tokenizes `line` from `state` (the line before's end), leaving it as this line ends; the runs
	/// in order, those of one token joined, in `out`.
	public void Tokenize(StringView line, ref CodeLexState state, List<CodeSpan> @out)
	{
		@out.Clear();
		if (!mPrepared || Contexts.IsEmpty)
		{
			if (line.Length != 0)
				@out.Add(.(0, (uint32)line.Length, .Text));
			return;
		}
		// A local method cannot capture an @-escaped parameter, so it reaches the list by this name.
		let spans = @out;
		void Emit(int start, int end, CodeToken token)
		{
			if (end <= start)
				return;
			if (!spans.IsEmpty && (spans.Back.End == (uint32)start) && (spans.Back.Token == token))
				spans.Back.End = (uint32)end;
			else
				spans.Add(.((uint32)start, (uint32)end, token));
		}
		int pos = 0;
		while (pos < line.Length)
		{
			let top = ((int)state.Top < Contexts.Count) ? state.Top : 0;
			let context = Contexts[top];
			if (!context.Escape.IsEmpty && StartsAt(line, pos, context.Escape))
			{
				let end = Math.Min(line.Length, NextChar(line, pos + context.Escape.Length));
				Emit(pos, end, .Escape);
				pos = end;
				continue;
			}
			bool matched = false;
			let ruleBase = RuleBase(top);
			for (int r < context.Rules.Count)
			{
				let rule = context.Rules[r];
				if (rule.LineStart && !OnlySpaceBefore(line, pos))
					continue;
				uint8 level = state.Level;
				let length = MatchAt(rule, line, pos, ref level);
				if (length == 0)
					continue;
				var token = rule.Token;
				if (rule.Match == .Identifier)
				{
					if (mWords.TryGetValueAlt(line.Substring(pos, length), let named))
						token = named;
				}
				Emit(pos, pos + length, token);
				pos += length;
				for (uint8 i = 0; (i < rule.Leave) && (state.Depth > 0); ++i)
					--state.Depth;
				let enter = mEnter[ruleBase + r];
				if ((enter >= 0) && (state.Depth < CodeLexState.cDepth))
					state.Stack[state.Depth++] = (uint8)enter;
				if (rule.Match == .LongOpen)
					state.Level = level;
				matched = true;
				break;
			}
			if (matched)
				continue;
			let end = NextChar(line, pos);
			Emit(pos, end, context.Token);
			pos = end;
		}
		// A line comment, a preprocessor line: done where the line is.
		while ((state.Depth > 0) && ((int)state.Top < Contexts.Count) && Contexts[state.Top].EndsAtLineEnd)
			--state.Depth;
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		CodeLanguageDetail.Optional(ar, "id", Id);
		CodeLanguageDetail.Optional(ar, "name", Name);
		CodeLanguageDetail.Optional(ar, "extensions", Extensions);
		CodeLanguageDetail.Optional(ar, "identifierDashes", ref IdentifierDashes);
		CodeLanguageDetail.Optional(ar, "digitSeparators", DigitSeparators);
		CodeLanguageDetail.Optional(ar, "words", Words);
		CodeLanguageDetail.Optional(ar, "contexts", Contexts);
		CodeLanguageDetail.Optional(ar, "lineComment", LineComment);
		if ((ar.Mode != .Read) || ar.HasKey("blockComment"))
		{
			ar.Key("blockComment");
			BlockComment.Serialize(ar);
		}
		CodeLanguageDetail.Optional(ar, "brackets", Brackets);
		CodeLanguageDetail.Optional(ar, "autoClose", AutoClose);
		CodeLanguageDetail.Optional(ar, "indentAfter", IndentAfter);
		CodeLanguageDetail.Optional(ar, "outdentFirst", OutdentFirst);
		CodeLanguageDetail.Optional(ar, "foldByIndent", ref FoldByIndent);
		CodeLanguageDetail.Optional(ar, "regionStart", RegionStart);
		CodeLanguageDetail.Optional(ar, "regionEnd", RegionEnd);
		ar.EndObject();
		if (ar.Mode == .Read)
			Prepare();
	}

	private int RuleBase(uint8 context)
	{
		int @base = 0;
		for (uint8 i = 0; i < context; ++i)
			@base += Contexts[i].Rules.Count;
		return @base;
	}

	private static bool StartsAt(StringView line, int pos, StringView text)
	{
		return (text.Length != 0) && (pos + text.Length <= line.Length) && (line.Substring(pos, text.Length) == text);
	}

	private static int NextChar(StringView line, int pos)
	{
		var pos;
		++pos;
		while ((pos < line.Length) && (((uint8)line[pos] & 0xC0) == 0x80))
			++pos;
		return pos;
	}

	private static bool OnlySpaceBefore(StringView line, int pos)
	{
		for (int i < pos)
		{
			if ((line[i] != ' ') && (line[i] != '\t'))
				return false;
		}
		return true;
	}

	private static bool Holds(StringView set, char8 c)
	{
		for (let @in in set)
		{
			if (@in == c)
				return true;
		}
		return false;
	}

	private static bool IsDigit(char8 c) => (c >= '0') && (c <= '9');

	/// A digit of a number in `radix` (2, 8, 10 or 16).
	private static bool IsDigitOf(char8 c, int radix)
	{
		if (radix == 16)
			return IsDigit(c) || ((c >= 'a') && (c <= 'f')) || ((c >= 'A') && (c <= 'F'));
		return IsDigit(c) && (((int)c - (int)'0') < radix);
	}

	/// Whether the number goes on at `at` in `radix`: a digit, a '_', or one of the language's
	/// separators with a digit after it.
	private bool NumberGoesOn(StringView line, int at, int radix)
	{
		let c = line[at];
		if (IsDigitOf(c, radix) || (c == '_'))
			return true;
		return Holds(DigitSeparators, c) && (at + 1 < line.Length) && IsDigitOf(line[at + 1], radix);
	}

	/// Where a number's suffix (1.0f, 10u, 2ull) ends, from `end`.
	private static int SuffixEnd(StringView line, int end)
	{
		var end;
		while ((end < line.Length) && (((line[end] >= 'a') && (line[end] <= 'z')) || ((line[end] >= 'A') && (line[end] <= 'Z'))))
			++end;
		return end;
	}

	private static bool IsNameStart(char8 c)
	{
		return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || (c == '_') || ((uint8)c >= 0x80);
	}

	private bool IsNamePart(char8 c) => IsNameStart(c) || IsDigit(c) || (IdentifierDashes && (c == '-'));

	private int MatchAt(CodeRule rule, StringView line, int pos, ref uint8 level)
	{
		switch (rule.Match)
		{
		case .Literal:
			return StartsAt(line, pos, rule.Text) ? rule.Text.Length : 0;
		case .Identifier:
			{
				// With dashes (CSS), a name may begin with them: `-webkit-x`, `--token`.
				int start = pos;
				while (IdentifierDashes && (start < line.Length) && (line[start] == '-'))
					++start;
				if ((start >= line.Length) || !IsNameStart(line[start]) || ((pos > 0) && IsNamePart(line[pos - 1])))
					return 0;
				int end = pos + 1;
				while ((end < line.Length) && IsNamePart(line[end]))
					++end;
				return end - pos;
			}
		case .Number:
			{
				if ((pos > 0) && IsNamePart(line[pos - 1]))
					return 0; // a digit inside a name
				int end = pos;
				int radix = 0;
				if (StartsAt(line, pos, "0x") || StartsAt(line, pos, "0X"))
					radix = 16;
				else if (StartsAt(line, pos, "0b") || StartsAt(line, pos, "0B"))
					radix = 2;
				else if (StartsAt(line, pos, "0o") || StartsAt(line, pos, "0O"))
					radix = 8;
				if (radix != 0)
				{
					end += 2;
					while ((end < line.Length) && NumberGoesOn(line, end, radix))
						++end;
					if (end > pos + 2)
						return SuffixEnd(line, end) - pos;
					if (radix == 16)
						return 0;
					end = pos; // "0b" with no binary digit after: a 0 with a suffix, as before
				}
				let startsWithDot = line[pos] == '.';
				if (!IsDigit(line[pos]) && !(startsWithDot && (pos + 1 < line.Length) && IsDigit(line[pos + 1])))
					return 0;
				while ((end < line.Length) && NumberGoesOn(line, end, 10))
					++end;
				if ((end < line.Length) && (line[end] == '.') && !((end + 1 < line.Length) && (line[end + 1] == '.')))
				{
					++end;
					while ((end < line.Length) && (IsDigit(line[end]) || ((line[end] != '_') && NumberGoesOn(line, end, 10))))
						++end;
				}
				if ((end < line.Length) && ((line[end] == 'e') || (line[end] == 'E')))
				{
					int at = end + 1;
					if ((at < line.Length) && ((line[at] == '+') || (line[at] == '-')))
						++at;
					if ((at < line.Length) && IsDigit(line[at]))
					{
						end = at;
						while ((end < line.Length) && IsDigit(line[end]))
							++end;
					}
				}
				return SuffixEnd(line, end) - pos; // a suffix: 1.0f, 10u, 2ull
			}
		case .AnyOf:
			return Holds(rule.Text, line[pos]) ? 1 : 0;
		case .Run:
			{
				int end = pos;
				while ((end < line.Length) && Holds(rule.Text, line[end]))
					++end;
				return end - pos;
			}
		case .LineRest:
			return line.Length - pos;
		case .LongOpen:
			{
				if (rule.Text.IsEmpty || (line[pos] != rule.Text[0]))
					return 0;
				int end = pos + 1;
				uint8 equals = 0;
				while ((end < line.Length) && (line[end] == '='))
				{
					++end;
					++equals;
				}
				if ((end >= line.Length) || (line[end] != rule.Text[0]))
					return 0;
				level = equals;
				return end + 1 - pos;
			}
		case .LongClose:
			{
				if (rule.Text.IsEmpty || (line[pos] != rule.Text[0]))
					return 0;
				int end = pos + 1;
				for (uint8 i = 0; i < level; ++i, ++end)
				{
					if ((end >= line.Length) || (line[end] != '='))
						return 0;
				}
				if ((end >= line.Length) || (line[end] != rule.Text[0]))
					return 0;
				return end + 1 - pos;
			}
		}
	}
}

/// What CodeLanguage.bf keeps out of the public surface: the names of the tokens and the matches,
/// and how a definition reads its optional fields.
internal static class CodeLanguageDetail
{
	public static String[(int)CodeToken.Count] sCodeTokenNames = .(
		"text", "keyword", "type", "constant", "builtin", "number",
		"string", "escape", "comment", "preprocessor", "operator", "punctuation",
		"tag", "attribute", "property", "selector", "invalid");

	public static String[8] sCodeMatchNames = .(
		"literal", "identifier", "number", "any-of", "run", "line-rest", "long-open", "long-close");

	// A field read only where the definition has it (a definition writes only what it sets).
	public static void Optional(ISerializer ar, StringView key, String value)
	{
		if ((ar.Mode == .Read) && !ar.HasKey(key))
			return;
		Serialize(ar, key, value);
	}

	public static void Optional(ISerializer ar, StringView key, ref bool value)
	{
		if ((ar.Mode == .Read) && !ar.HasKey(key))
			return;
		ar.Key(key);
		Serialize(ar, ref value);
	}

	public static void Optional(ISerializer ar, StringView key, ref uint8 value)
	{
		if ((ar.Mode == .Read) && !ar.HasKey(key))
			return;
		ar.Key(key);
		Serialize(ar, ref value);
	}

	public static void Optional(ISerializer ar, StringView key, List<String> value)
	{
		if ((ar.Mode == .Read) && !ar.HasKey(key))
			return;
		ar.Key(key);
		SerializeList(ar, value);
	}

	public static void Optional<T>(ISerializer ar, StringView key, List<T> value) where T : ISerializable, class, new, delete
	{
		if ((ar.Mode == .Read) && !ar.HasKey(key))
			return;
		ar.Key(key);
		Objects<T>(ar, value);
	}

	// A list of definitions' parts, each describing itself, as the core's SerializeList moves one:
	// count prefixed; reading, what was there goes and each read part is new.
	private static void Objects<T>(ISerializer ar, List<T> list) where T : ISerializable, class, new, delete
	{
		uint32 count = (uint32)list.Count;
		ar.BeginArray(ref count);
		if ((ar.Mode == .Read) && !ar.IsPayloadOk)
			count = 0; // the read has failed: the count it read is not data
		if (ar.Mode == .Read)
		{
			ClearAndDeleteItems!(list);
			for (uint32 i < count)
			{
				let element = new T();
				element.Serialize(ar);
				if (!ar.IsPayloadOk)
				{
					delete element;
					break;
				}
				list.Add(element);
			}
		}
		else
		{
			for (let element in list)
				element.Serialize(ar);
		}
		ar.EndArray();
	}

	// A token by its name (`keyword`).
	public static void TokenField(ISerializer ar, StringView key, ref CodeToken token)
	{
		let name = scope String(CodeTokenName(token));
		if ((ar.Mode == .Read) && !ar.HasKey(key))
			return;
		Serialize(ar, key, name);
		token = CodeTokenNamed(name);
	}

	public static void CopyPairs(List<CodePair> from, List<CodePair> to)
	{
		ClearAndDeleteItems!(to);
		for (let pair in from)
			to.Add(new CodePair(pair.Open, pair.Close));
	}
}
