using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The syntax lexers and the incremental cache over them.
class CodeLexerTests
{
	private static StringView[4] TestKeywords = .("class", "if", "return", "var");
	private static StringView[3] TestTypes = .("System", "float4", "int");

	/// Counts how many times a line is actually lexed, which is the only way to observe the
	/// cache's laziness from outside.
	private class CountingLexer : ICodeLexer
	{
		private ICodeLexer mInner;
		public int32 Calls = 0;

		public this(ICodeLexer inner)
		{
			mInner = inner;
		}

		public uint32 LexLine(StringView line, uint32 entryState, List<CodeToken> outTokens)
		{
			Calls++;
			return mInner.LexLine(line, entryState, outTokens);
		}
	}

	private static StringView TextOf(StringView line, CodeToken token) =>
		line.Substring(token.ByteBegin, token.ByteEnd - token.ByteBegin);

	/// The token whose text is exactly this, or a default one with nothing in it.
	private static bool TryFind(List<CodeToken> tokens, StringView line, StringView text,
		out CodeToken found)
	{
		for (let token in tokens)
		{
			if (TextOf(line, token) == text)
			{
				found = token;
				return true;
			}
		}

		found = .();
		return false;
	}

	private static void AssertKind(List<CodeToken> tokens, StringView line, StringView text,
		CodeTokenKind expected)
	{
		Test.Assert(TryFind(tokens, line, text, let token), scope $"no token for \"{text}\"");
		Test.Assert(token.Kind == expected,
			scope $"\"{text}\" lexed as {token.Kind}, expected {expected}");
	}

	// ---- The C shaped lexer ---------------------------------------------------------------------

	[Test]
	public static void TheCLikeLexerClassifiesItsTokens()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let tokens = scope List<CodeToken>();

		let line = "var count = 0x1F + 2.5e-3 // tail";
		let exit = lexer.LexLine(line, 0, tokens);

		AssertKind(tokens, line, "var", .Keyword);
		AssertKind(tokens, line, "count", .Default);
		AssertKind(tokens, line, "0x1F", .Number);
		AssertKind(tokens, line, "2.5e-3", .Number);
		AssertKind(tokens, line, "// tail", .Comment);
		AssertKind(tokens, line, "=", .Operator);
		Test.Assert(exit == 0);
	}

	private static CLikeLexerSpec MakeSpec(bool nested = false, bool triple = false,
		bool preprocessor = false, bool chars = false)
	{
		CLikeLexerSpec spec = .();
		spec.Keywords = TestKeywords;
		spec.Types = TestTypes;
		spec.NestedBlockComments = nested;
		spec.TripleQuotedStrings = triple;
		spec.HashPreprocessorLines = preprocessor;
		spec.CharLiterals = chars;
		return spec;
	}

	[Test]
	public static void StringsKeepTheirEscapedQuotes()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let tokens = scope List<CodeToken>();

		let line = "System.print(\"hi \\\" there\")";
		lexer.LexLine(line, 0, tokens);

		AssertKind(tokens, line, "System", .Type);
		AssertKind(tokens, line, "(", .Punctuation);
		// An escaped quote does NOT end the string.
		AssertKind(tokens, line, "\"hi \\\" there\"", .String);
	}

	/// Whether a block comment nests is a language's own rule, and it changes what the SAME
	/// text means.
	[Test]
	public static void BlockCommentNestingIsConfigurable()
	{
		let tokens = scope List<CodeToken>();

		// Without nesting, the first terminator closes it however many were opened.
		let flat = scope CLikeLexer(MakeSpec(false));
		let flatOpen = flat.LexLine("a /* outer /* inner", 0, tokens);
		Test.Assert(flatOpen != 0);

		tokens.Clear();
		let flatLine = "done */ var x";
		Test.Assert(flat.LexLine(flatLine, flatOpen, tokens) == 0);
		AssertKind(tokens, flatLine, "var", .Keyword);

		// With nesting, each open needs its own close.
		let nested = scope CLikeLexer(MakeSpec(true));
		tokens.Clear();
		let nestedOpen = nested.LexLine("a /* outer /* inner", 0, tokens);
		Test.Assert(nestedOpen != 0);

		tokens.Clear();
		let still = nested.LexLine("still */ inside", nestedOpen, tokens);
		Test.Assert(still != 0, "one close is not enough for two opens");
		Test.Assert(tokens.Count == 1);
		Test.Assert(tokens[0].Kind == .Comment);

		tokens.Clear();
		let nestedLine = "done */ var x";
		Test.Assert(nested.LexLine(nestedLine, still, tokens) == 0);
		AssertKind(tokens, nestedLine, "var", .Keyword);
	}

	[Test]
	public static void TripleQuotedStringsSpanLines()
	{
		let lexer = scope CLikeLexer(MakeSpec(false, true));
		let tokens = scope List<CodeToken>();

		let open = lexer.LexLine("var s = \"\"\"first", 0, tokens);
		Test.Assert(open != 0);

		tokens.Clear();
		let middle = lexer.LexLine("raw \"quotes\" fine here", open, tokens);
		Test.Assert(middle != 0);
		Test.Assert(tokens.Count == 1, "ordinary quotes inside are just text");
		Test.Assert(tokens[0].Kind == .String);

		tokens.Clear();
		let line = "end\"\"\" + tail";
		Test.Assert(lexer.LexLine(line, middle, tokens) == 0);
		AssertKind(tokens, line, "tail", .Default);
	}

	/// A hash line is ONE token whatever is on it, including what would otherwise be a comment.
	[Test]
	public static void APreprocessorLineIsOneToken()
	{
		let lexer = scope CLikeLexer(MakeSpec(false, false, true, true));
		let tokens = scope List<CodeToken>();

		lexer.LexLine("  #include \"common.hlsli\" // note", 0, tokens);
		Test.Assert(tokens.Count == 1);
		Test.Assert(tokens[0].Kind == .Preprocessor);
	}

	[Test]
	public static void CharacterLiteralsLexAsStrings()
	{
		let lexer = scope CLikeLexer(MakeSpec(false, false, true, true));
		let tokens = scope List<CodeToken>();

		let line = "float4 c = 'x' + 1.0f;";
		lexer.LexLine(line, 0, tokens);

		AssertKind(tokens, line, "float4", .Type);
		AssertKind(tokens, line, "'x'", .String);
		AssertKind(tokens, line, "1.0f", .Number);
	}

	// ---- The Lua shaped lexer -------------------------------------------------------------------

	private static LuaLikeLexerSpec MakeLuaSpec()
	{
		LuaLikeLexerSpec spec = .();
		spec.Keywords = TestLuaKeywords;
		spec.Types = TestLuaTypes;
		return spec;
	}

	private static StringView[4] TestLuaKeywords = .("local", "function", "end", "return");
	private static StringView[2] TestLuaTypes = .("number", "string");

	[Test]
	public static void TheLuaLikeLexerUsesItsOwnCommentMarker()
	{
		let lexer = scope LuaLikeLexer(MakeLuaSpec());
		Test.Assert(lexer.LineCommentPrefix == "--");

		let tokens = scope List<CodeToken>();
		let line = "local x = 0xFF -- a tail comment";
		Test.Assert(lexer.LexLine(line, 0, tokens) == 0);

		AssertKind(tokens, line, "local", .Keyword);
		AssertKind(tokens, line, "x", .Default);
		AssertKind(tokens, line, "0xFF", .Number);
		AssertKind(tokens, line, "-- a tail comment", .Comment);
	}

	/// Two slashes are NOT a comment here, which is the kind of thing a shared lexer would get
	/// wrong.
	[Test]
	public static void SlashesAreNotACommentInLua()
	{
		let lexer = scope LuaLikeLexer(MakeLuaSpec());
		let tokens = scope List<CodeToken>();

		let line = "local y = a // b";
		Test.Assert(lexer.LexLine(line, 0, tokens) == 0);
		AssertKind(tokens, line, "b", .Default);
	}

	[Test]
	public static void AllThreeQuotingFormsLexAsStrings()
	{
		let lexer = scope LuaLikeLexer(MakeLuaSpec());
		let tokens = scope List<CodeToken>();

		let line = "local s = `hi {x}` .. \"z\" .. 'q'";
		lexer.LexLine(line, 0, tokens);

		AssertKind(tokens, line, "`hi {x}`", .String);
		AssertKind(tokens, line, "\"z\"", .String);
		AssertKind(tokens, line, "'q'", .String);
	}

	/// A long bracket closes only at its OWN level, which is the whole reason the notation
	/// exists and what the carried state has to remember.
	[Test]
	public static void LongStringsCarryTheirLevelAcrossLines()
	{
		let lexer = scope LuaLikeLexer(MakeLuaSpec());
		let tokens = scope List<CodeToken>();

		let open = "local s = [==[ start";
		let openState = lexer.LexLine(open, 0, tokens);
		AssertKind(tokens, open, "[==[ start", .String);
		Test.Assert(openState != 0);

		tokens.Clear();
		let wrongState = lexer.LexLine("middle ]=] still going", openState, tokens);
		Test.Assert(wrongState == openState, "a close at the wrong level is not a close");

		tokens.Clear();
		let close = "end ]==] after";
		Test.Assert(lexer.LexLine(close, wrongState, tokens) == 0);
		AssertKind(tokens, close, "end ]==]", .String);
		AssertKind(tokens, close, "after", .Default);
	}

	[Test]
	public static void LongCommentsCarryAcrossLines()
	{
		let lexer = scope LuaLikeLexer(MakeLuaSpec());
		let tokens = scope List<CodeToken>();

		let open = "--[[ block";
		let openState = lexer.LexLine(open, 0, tokens);
		AssertKind(tokens, open, "--[[ block", .Comment);
		Test.Assert(openState != 0);

		tokens.Clear();
		let close = "done ]] code";
		Test.Assert(lexer.LexLine(close, openState, tokens) == 0);
		AssertKind(tokens, close, "done ]]", .Comment);
		AssertKind(tokens, close, "code", .Default);
	}

	// ---- The markup lexer -----------------------------------------------------------------------

	[Test]
	public static void MarkupSeparatesTagsAttributesAndText()
	{
		let lexer = scope XmlLexer();
		let tokens = scope List<CodeToken>();

		let line = "<Panel width=\"120\">hello</Panel>";
		Test.Assert(lexer.LexLine(line, 0, tokens) == 0);

		AssertKind(tokens, line, "Panel", .Tag);
		AssertKind(tokens, line, "width", .Attribute);
		AssertKind(tokens, line, "\"120\"", .String);
		AssertKind(tokens, line, "hello", .Default);
	}

	[Test]
	public static void ADeclarationIsOneToken()
	{
		let lexer = scope XmlLexer();
		let tokens = scope List<CodeToken>();

		lexer.LexLine("<?xml version=\"1.0\"?>", 0, tokens);
		Test.Assert(tokens.Count == 1);
		Test.Assert(tokens[0].Kind == .Preprocessor);
	}

	[Test]
	public static void MarkupCommentsAndOpenTagsCarryAcrossLines()
	{
		let lexer = scope XmlLexer();
		let tokens = scope List<CodeToken>();

		let openState = lexer.LexLine("<!-- start", 0, tokens);
		Test.Assert(openState != 0);

		tokens.Clear();
		let closeLine = "end --><Row/>";
		Test.Assert(lexer.LexLine(closeLine, openState, tokens) == 0);
		AssertKind(tokens, closeLine, "end -->", .Comment);
		AssertKind(tokens, closeLine, "Row", .Tag);

		// A tag left open carries too, so its attributes continue on the next line.
		tokens.Clear();
		let tagState = lexer.LexLine("<Button", 0, tokens);
		Test.Assert(tagState != 0);

		tokens.Clear();
		let attrLine = "    label=\"Go\" />";
		Test.Assert(lexer.LexLine(attrLine, tagState, tokens) == 0);
		AssertKind(tokens, attrLine, "label", .Attribute);
	}

	/// Markup has only block comments, so there is nothing for a comment toggle to insert.
	[Test]
	public static void MarkupDisablesTheCommentToggle()
	{
		let lexer = scope XmlLexer();
		Test.Assert(lexer.LineCommentPrefix.IsEmpty);
	}

	// ---- Columns --------------------------------------------------------------------------------

	/// A token carries both a byte offset and a column, and the two DIVERGE the moment a
	/// multibyte character appears. Placing text by its byte offset would drift.
	[Test]
	public static void TokenColumnsCountCodepoints()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let tokens = scope List<CodeToken>();

		let line = "var h\u{00E9}llo=1";
		lexer.LexLine(line, 0, tokens);

		Test.Assert(TryFind(tokens, line, "1", let number));
		Test.Assert(number.Column == 10);
		Test.Assert(number.ByteBegin == 11, "one byte further along than its column");
	}

	// ---- The registry ---------------------------------------------------------------------------

	[Test]
	public static void TheRegistryIsCaseInsensitiveAndLastWins()
	{
		CodeLexerRegistry.Clear();
		defer CodeLexerRegistry.Clear();

		CodeLexerRegistry.Register("testlang", new () => (ICodeLexer)(new CLikeLexer(MakeSpec())));

		let found = CodeLexerRegistry.Create("testlang");
		Test.Assert(found != null);
		delete found;

		let shouted = CodeLexerRegistry.Create("TESTLANG");
		Test.Assert(shouted != null, "names come from extensions and configuration");
		delete shouted;

		Test.Assert(CodeLexerRegistry.Create("nosuchlang") == null,
			"an unknown language leaves the text unstyled rather than failing");

		// Registering again REPLACES, so a module can override one registered before it.
		CodeLexerRegistry.Register("testlang", new () => (ICodeLexer)null);
		Test.Assert(CodeLexerRegistry.Create("testlang") == null);
	}

	// ---- The incremental cache ------------------------------------------------------------------

	/// Typing inside a line re-lexes ONE line, because the state coming out of it is unchanged
	/// and the cache converges immediately after.
	[Test]
	public static void AnEditThatChangesNoStateRelexesOneLine()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let counting = scope CountingLexer(lexer);

		let doc = scope CodeDocument();
		doc.SetText("var a = 1\nvar b = 2\nvar c = 3\nvar d = 4");

		let highlighter = scope CodeHighlighter();
		highlighter.SetLexer(counting);
		highlighter.Reset(doc.LineCount);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);
		Test.Assert(counting.Calls == 4, "the initial full lex");

		doc.Edit(.(.(1, 4), .(1, 5)), "x", .Typing, .(), 0.0);
		highlighter.OnLinesChanged(1, 1, 1);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);
		Test.Assert(counting.Calls == 5);
	}

	/// Opening a block comment CASCADES: every following line means something different now,
	/// and closing it puts them all back.
	[Test]
	public static void AStateChangeCascadesAndRecovers()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let counting = scope CountingLexer(lexer);

		let doc = scope CodeDocument();
		doc.SetText("var a = 1\nvar b = 2\nvar c = 3\nvar d = 4");

		let highlighter = scope CodeHighlighter();
		highlighter.SetLexer(counting);
		highlighter.Reset(doc.LineCount);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);

		doc.Edit(.(.(0, 9), .(0, 9)), " /*", .Typing, .(), 1.0);
		highlighter.OnLinesChanged(0, 1, 1);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);
		Test.Assert(counting.Calls == 8, "the edited line and all three below it");
		Test.Assert(highlighter.TokensFor(3).Length == 1);
		Test.Assert(highlighter.TokensFor(3)[0].Kind == .Comment);

		doc.Edit(.(.(0, 12), .(0, 12)), "*/", .Typing, .(), 2.0);
		highlighter.OnLinesChanged(0, 1, 1);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);
		Test.Assert(counting.Calls == 12);
		Test.Assert(highlighter.TokensFor(3)[0].Kind == .Keyword, "code again");
	}

	/// Splicing a line in SHIFTS the cache rather than invalidating everything below it, so the
	/// tail converges without being re-lexed.
	[Test]
	public static void ASpliceKeepsTheTailValid()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let counting = scope CountingLexer(lexer);

		let doc = scope CodeDocument();
		doc.SetText("var a = 1\nvar b = 2\nvar c = 3");

		let highlighter = scope CodeHighlighter();
		highlighter.SetLexer(counting);
		highlighter.Reset(doc.LineCount);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);
		let initial = counting.Calls;

		doc.Edit(.(.(0, 9), .(0, 9)), "\nvar n = 9", .Paste, .(), 0.0);
		highlighter.OnLinesChanged(0, 1, 2);
		highlighter.EnsureLexed(doc, doc.LineCount - 1);

		Test.Assert(counting.Calls == initial + 2, "only the edited line and the new one");
		Test.Assert(highlighter.TokensFor(3).Length > 0, "the shifted cache survived");
	}

	/// A file with a thousand lines below the viewport costs nothing until it is scrolled to.
	[Test]
	public static void TheLazyFrontierResumesWhereItStopped()
	{
		let lexer = scope CLikeLexer(MakeSpec());
		let counting = scope CountingLexer(lexer);

		let doc = scope CodeDocument();
		doc.SetText("/* open\nline1\nline2\nline3 */\nvar tail = 1");

		let highlighter = scope CodeHighlighter();
		highlighter.SetLexer(counting);
		highlighter.Reset(doc.LineCount);

		highlighter.EnsureLexed(doc, 1);
		Test.Assert(counting.Calls == 2);
		Test.Assert(highlighter.TokensFor(2).Length == 0, "below the frontier, not yet lexed");

		highlighter.EnsureLexed(doc, 4);
		Test.Assert(counting.Calls == 5);
		Test.Assert(highlighter.TokensFor(1)[0].Kind == .Comment);
		Test.Assert(highlighter.TokensFor(4).Length > 0);
		Test.Assert(highlighter.TokensFor(4)[0].Kind == .Keyword);
	}
}
