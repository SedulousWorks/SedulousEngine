using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.GUI;
using static Sedulous.GUI.Code.Tests.CodeFixtures;

namespace Sedulous.GUI.Code.Tests;

/// A language's definition and its tokenizer: rules in contexts give runs their tokens, words name
/// identifiers, a state carries a block comment and a long bracket from line to line; a definition
/// read back from the engine's XML tokenizes alike; the editor keeps each line's tokens, tokenizing
/// again only what changed or what a change reaches.
class CodeLanguageTests
{
	public static CodeRule Rule(CodeMatch match, StringView text, CodeToken token, StringView enter = default, uint8 leave = 0)
	{
		let rule = new CodeRule();
		rule.Match = match;
		rule.Text.Set(text);
		rule.Token = token;
		rule.Enter.Set(enter);
		rule.Leave = leave;
		return rule;
	}

	public static CodeContext Context(StringView name, CodeToken token)
	{
		let context = new CodeContext();
		context.Name.Set(name);
		context.Token = token;
		return context;
	}

	/// A small C-like language: comments, strings with escapes, `#` lines, keywords and types. The
	/// caller owns it.
	public static CodeLanguage CLike()
	{
		let lang = new CodeLanguage();
		lang.Id.Set("clike");
		lang.Words.Add(new CodeWords(.Keyword, "if else return for"));
		lang.Words.Add(new CodeWords(.Type, "int float"));
		let root = Context("code", .Text);
		let pound = Rule(.Literal, "#", .Preprocessor, "directive");
		pound.LineStart = true;
		root.Rules.Add(pound);
		root.Rules.Add(Rule(.Literal, "//", .Comment, "line-comment"));
		root.Rules.Add(Rule(.Literal, "/*", .Comment, "block-comment"));
		root.Rules.Add(Rule(.Literal, "\"", .String, "string"));
		root.Rules.Add(Rule(.Identifier, "", .Text));
		root.Rules.Add(Rule(.Number, "", .Number));
		root.Rules.Add(Rule(.AnyOf, "+-*/=<>!&|", .Operator));
		root.Rules.Add(Rule(.AnyOf, "(){}[];,.", .Punctuation));
		lang.Contexts.Add(root);
		let line = Context("line-comment", .Comment);
		line.EndsAtLineEnd = true;
		lang.Contexts.Add(line);
		let block = Context("block-comment", .Comment);
		block.Rules.Add(Rule(.Literal, "*/", .Comment, "", 1));
		lang.Contexts.Add(block);
		let string = Context("string", .String);
		string.Escape.Set("\\");
		string.EndsAtLineEnd = true;
		string.Rules.Add(Rule(.Literal, "\"", .String, "", 1));
		lang.Contexts.Add(string);
		let directive = Context("directive", .Preprocessor);
		directive.EndsAtLineEnd = true;
		lang.Contexts.Add(directive);
		lang.Prepare();
		return lang;
	}

	/// "token:text" for each run, space-separated: what a line tokenized to, appended to `outText`.
	public static String Runs(CodeLanguage lang, StringView line, ref CodeLexState state, String outText)
	{
		let spans = scope List<CodeSpan>();
		lang.Tokenize(line, ref state, spans);
		void Add(StringView token, StringView text)
		{
			if (!outText.IsEmpty)
				outText.Append(" ");
			outText.Append(token);
			outText.Append(":");
			outText.Append(text);
		}
		for (let span in spans)
		{
			let text = line.Substring((int)span.Start, (int)span.End - (int)span.Start);
			if (span.Token != .Text)
			{
				Add(CodeTokenName(span.Token), text);
				continue;
			}
			// Plain text's runs join (the spaces between names too): each word apart here.
			int at = 0;
			while (at < text.Length)
			{
				while ((at < text.Length) && (text[at] == ' '))
					++at;
				int end = at;
				while ((end < text.Length) && (text[end] != ' '))
					++end;
				if (end > at)
					Add("text", text.Substring(at, end - at));
				at = end;
			}
		}
		return outText;
	}

	/// Asserts `line` tokenizes from `state` to `expected`, saying what it gave when it does not.
	public static void CheckRuns(CodeLanguage lang, StringView line, ref CodeLexState state, StringView expected)
	{
		let runs = Runs(lang, line, ref state, .. scope String());
		Test.Assert(runs == expected, scope String()..AppendF("the runs: {}", runs));
	}

	[Test]
	public static void RulesGiveRunsTheirTokensWordsNameIdentifiersNumbersStringsAndEscapes()
	{
		let lang = CLike();
		defer delete lang;
		var state = CodeLexState();
		CheckRuns(lang, "int x = 0x1F + 2.5f;", ref state, "type:int text:x operator:= number:0x1F operator:+ number:2.5f punctuation:;");
		Test.Assert(state.Depth == 0);
		CheckRuns(lang, "return \"a\\\"b\"; // done", ref state, "keyword:return string:\"a escape:\\\" string:b\" punctuation:; comment:// done");
		Test.Assert(state.Depth == 0); // the line comment ends with its line
		CheckRuns(lang, "  #include <x>", ref state, "preprocessor:#include <x>");
		CheckRuns(lang, "a # b", ref state, "text:a text:# text:b"); // not first on its line
		CheckRuns(lang, "x2 = \u{00E9}lan", ref state, "text:x2 operator:= text:\u{00E9}lan");
	}

	[Test]
	public static void ABlockCommentCarriesToTheNextLinesTheStateSayingSo()
	{
		let lang = CLike();
		defer delete lang;
		var state = CodeLexState();
		CheckRuns(lang, "int a; /* start", ref state, "type:int text:a punctuation:; comment:/* start");
		Test.Assert(state.Depth == 1);
		let inside = state;
		CheckRuns(lang, "still", ref state, "comment:still");
		Test.Assert(state == inside);
		CheckRuns(lang, "end */ if", ref state, "comment:end */ keyword:if");
		Test.Assert(state.Depth == 0);
	}

	/// A number's prefix (0x, 0b, 0o) takes its digits and a suffix; the language's digit separators
	/// join digits only where a digit follows, so without them, or at a number's end, the separator
	/// is not the number's. A copy of the language separates alike.
	[Test]
	public static void ANumbersPrefixesAndItsLanguagesDigitSeparators()
	{
		let lang = CLike();
		defer delete lang;
		var state = CodeLexState();
		CheckRuns(lang, "x = 0b1010 + 0o17 + 0x1Fu;", ref state,
			"text:x operator:= number:0b1010 operator:+ number:0o17 operator:+ number:0x1Fu punctuation:;");
		CheckRuns(lang, "0bad", ref state, "number:0bad"); // no binary digit: a 0 and its suffix, as before
		CheckRuns(lang, "1'000", ref state, "number:1 text:' number:000"); // no separators: not the number's

		lang.DigitSeparators.Set("'");
		CheckRuns(lang, "1'000'000 + 0xFFFF'FFFF + 0x'FF + 2'5.0'1f", ref state,
			"number:1'000'000 operator:+ number:0xFFFF'FFFF operator:+ number:0x'FF operator:+ number:2'5.0'1f");
		CheckRuns(lang, "n = 1'", ref state, "text:n operator:= number:1 text:'");
		CheckRuns(lang, "0b10'01 0o7'7", ref state, "number:0b10'01 number:0o7'7");
		CheckRuns(lang, "0b1'2", ref state, "number:0b1 text:' number:2"); // 2 is no binary digit

		let copy = scope CodeLanguage();
		copy.Set(lang);
		Test.Assert(copy.DigitSeparators == "'");
		CheckRuns(copy, "1'000", ref state, "number:1'000");
	}

	[Test]
	public static void ALongBracketClosesAtItsOwnLevel()
	{
		let lang = scope CodeLanguage();
		let root = Context("code", .Text);
		root.Rules.Add(Rule(.LongOpen, "[", .String, "long"));
		root.Rules.Add(Rule(.Identifier, "", .Text));
		lang.Contexts.Add(root);
		let longString = Context("long", .String);
		longString.Rules.Add(Rule(.LongClose, "]", .String, "", 1));
		lang.Contexts.Add(longString);
		lang.Prepare();
		var state = CodeLexState();
		CheckRuns(lang, "x [==[ a ]=] b", ref state, "text:x string:[==[ a ]=] b");
		Test.Assert(state.Depth == 1);
		Test.Assert(state.Level == 2);
		CheckRuns(lang, "c ]==] y", ref state, "string:c ]==] text:y");
		Test.Assert(state.Depth == 0);
	}

	[Test]
	public static void ADefinitionWrittenByTheEnginesXmlAndReadBackTokenizesAlike()
	{
		let lang = CLike();
		defer delete lang;
		let writer = scope XmlSerializer();
		Serialize(writer, lang);
		let text = writer.GetOutput(.. scope String());
		Test.Assert(writer.IsOk);

		let doc = scope XmlDocument();
		Test.Assert(doc.Parse(text) == .Ok);
		let reader = scope XmlSerializer(doc);
		let read = scope CodeLanguage();
		Serialize(reader, read);
		Test.Assert(reader.IsOk);
		Test.Assert(read.Id == "clike");
		Test.Assert(read.Contexts.Count == lang.Contexts.Count);
		var a = CodeLexState();
		var b = CodeLexState();
		let line = "float y = 1; /* c */ \"s\\n\"";
		Test.Assert(Runs(read, line, ref a, .. scope String()) == Runs(lang, line, ref b, .. scope String()));
		Test.Assert(a == b);
	}

	[Test]
	public static void TheEditorKeepsEachLinesTokensTokenizingAgainOnlyWhatChangedOrWhatAChangeReaches()
	{
		let lang = CLike();
		defer delete lang;
		let editor = new CodeEditor();
		defer editor.ReleaseRef();
		let text = scope String();
		for (int i = 0; i < 50; ++i)
			text.Append("int a = 1;\n");
		editor.SetText(text);
		editor.SetLanguage(lang);
		Test.Assert(editor.TokensOf(10).Length > 0);
		Test.Assert(editor.TokensOf(10)[0].Token == .Type);
		let first = editor.TokenizedCount;
		Test.Assert(first == 11); // lines 0 to 10, as far as asked
		// An edit that leaves the state as it was: that line alone.
		editor.Document.Replace(.(.(3, 8), .(3, 9)), "2");
		editor.TokensOf(10);
		Test.Assert(editor.TokenizedCount == first + 1);
		// Opening a block comment: the lines after it, as they are asked for, change their tokens.
		editor.Document.Insert(.(5, 0), "/*");
		Test.Assert(editor.TokensOf(8)[0].Token == .Comment);
		Test.Assert(editor.TokenizedCount == first + 1 + 4); // 5 to 8
		// Closing it: back as they were.
		editor.Document.Insert(.(5, 2), "*/");
		Test.Assert(editor.TokensOf(8)[0].Token == .Type);
	}

	[Test]
	public static void TheSandboxsDefinitionsReadEachTokenizingItsLanguage()
	{
		let beef = scope CodeLanguage();
		let luau = scope CodeLanguage();
		let hlsl = scope CodeLanguage();
		let markup = scope CodeLanguage();
		let css = scope CodeLanguage();
		Test.Assert(LoadSandboxLanguage("beef", beef));
		Test.Assert(LoadSandboxLanguage("luau", luau));
		Test.Assert(LoadSandboxLanguage("hlsl", hlsl));
		Test.Assert(LoadSandboxLanguage("xml", markup));
		Test.Assert(LoadSandboxLanguage("css", css));
		Test.Assert(beef.Name == "Beef");
		Test.Assert(luau.Extensions.Count == 2);

		var state = CodeLexState();
		CheckRuns(beef, "int x = 3; // set", ref state, "type:int text:x operator:= number:3 punctuation:; comment:// set");
		CheckRuns(beef, "let s = \"a\\\"b\";", ref state, "keyword:let text:s operator:= string:\"a escape:\\\" string:b\" punctuation:;");
		CheckRuns(beef, "x = \"\"\"long", ref state, "text:x operator:= string:\"\"\"long");
		Test.Assert(state.Depth == 1); // a triple-quoted string goes on
		CheckRuns(beef, "text\"\"\" + y", ref state, "string:text\"\"\" operator:+ text:y");

		state = CodeLexState();
		CheckRuns(luau, "local t = {} -- note", ref state, "keyword:local text:t operator:= punctuation:{} comment:-- note");
		CheckRuns(luau, "--[[ a long", ref state, "comment:--[[ a long");
		Test.Assert(state.Depth == 1);
		CheckRuns(luau, "comment ]] print(1)", ref state, "comment:comment ]] builtin:print punctuation:( number:1 punctuation:)");
		CheckRuns(luau, "s = a .. [==[x]==]", ref state, "text:s operator:= text:a operator:.. string:[==[x]==]");

		state = CodeLexState();
		CheckRuns(hlsl, "float4 main(float2 uv : TEXCOORD0) : SV_Target", ref state,
			"type:float4 text:main punctuation:( type:float2 text:uv punctuation:: text:TEXCOORD0 punctuation:) punctuation:: builtin:SV_Target");
		CheckRuns(hlsl, "#include \"common.hlsl\"", ref state, "preprocessor:#include \"common.hlsl\"");
		CheckRuns(hlsl, "properties { Color tint; }", ref state, "keyword:properties punctuation:{ type:Color text:tint punctuation:; punctuation:}");

		state = CodeLexState();
		CheckRuns(markup, "<Button id=\"go\" text='Go'/> <!-- c -->", ref state,
			"punctuation:< tag:Button attribute:id punctuation:= string:\"go\" attribute:text punctuation:= string:'Go' punctuation:/> comment:<!-- c -->");
		CheckRuns(markup, "</Panel>&amp;", ref state, "punctuation:</ tag:Panel punctuation:> escape:&amp;");

		state = CodeLexState();
		CheckRuns(css, ".btn:hover { color: #ff8000; width: 12px !important; }", ref state,
			"punctuation:. selector:btn punctuation:: selector:hover punctuation:{ property:color punctuation:: constant:#ff8000 punctuation:; property:width punctuation:: number:12px keyword:!important punctuation:; punctuation:}");
		Test.Assert(state.Depth == 0);
		CheckRuns(css, "toast { background: var(--toast-background, #222); }", ref state,
			"selector:toast punctuation:{ property:background punctuation:: builtin:var punctuation:( text:--toast-background punctuation:, constant:#222 punctuation:); punctuation:}");
	}
}
