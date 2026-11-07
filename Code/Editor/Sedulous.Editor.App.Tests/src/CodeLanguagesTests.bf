using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// The code languages: each of the shared definitions (Data/Editor/Code) read by its id the first
/// time it is asked for and kept, one with no file none (and not read again); Beef's colours a
/// game's code.
class CodeLanguagesTests
{
	[Test]
	public static void EachSharedDefinitionReadByItsIdOnceAnUnknownOneNone()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		int reads = 0;
		let languages = scope CodeLanguages(new [&reads, =data] (path, outText) =>
			{
				reads++;
				return System.IO.File.ReadAllText(PathJoin(data, path, .. scope .()), outText) case .Ok;
			});
		for (let id in StringView[?]("angelscript", "luau", "hlsl", "xml", "css", "beef"))
		{
			let language = languages.Find(id);
			Test.Assert(language != null);
			Test.Assert(!language.Contexts.IsEmpty);
			Test.Assert(languages.Find(id) === language, "kept: the same, not read again");
		}
		Test.Assert(reads == 6);
		Test.Assert(languages.Find("cobol") == null);
		Test.Assert(languages.Find("cobol") == null);
		Test.Assert(reads == 7, "a miss is kept too");
		Test.Assert(languages.Find("") == null);
	}

	/// What a line of `language` tokenizes to from `state`: "token:text" for each run that is not
	/// plain text, space-separated, into `outText`.
	private static void Runs(CodeLanguage language, StringView line, ref CodeLexState state, String outText)
	{
		let spans = scope List<CodeSpan>();
		language.Tokenize(line, ref state, spans);
		for (let span in spans)
		{
			if (span.Token == .Text)
				continue;
			if (!outText.IsEmpty)
				outText.Append(" ");
			outText.AppendF("{}:{}", CodeTokenName(span.Token), line.Substring((int)span.Start, (int)span.End - (int)span.Start));
		}
	}

	private static void CheckRuns(CodeLanguage language, StringView line, ref CodeLexState state, StringView expected)
	{
		let runs = Runs(language, line, ref state, .. scope String());
		Test.Assert(runs == expected, scope String()..AppendF("'{}' gave: {}", line, runs));
	}

	/// Beef's definition, by its id and its extension: its keywords (those Beef's own tokenizer
	/// knows, `defer` and `scope` among them) and types, comments (a block comment nests),
	/// strings plain, interpolated, verbatim and multi-line, a character with its escape, numbers
	/// with their separators, an attribute opening its line, and a preprocessor line.
	[Test]
	public static void BeefColoursAGamesCode()
	{
		let data = scope String();
		Test.Assert(EditorSplashTests.DataRoot(data));
		let languages = scope CodeLanguages(new [=data] (path, outText) =>
			System.IO.File.ReadAllText(PathJoin(data, path, .. scope .()), outText) case .Ok);
		let beef = languages.Find("beef");
		Test.Assert(beef != null);
		Test.Assert(beef.Name == "Beef");
		Test.Assert((beef.Extensions.Count == 1) && (beef.Extensions[0] == "bf"));
		Test.Assert(beef.LineComment == "//");

		var state = CodeLexState();
		CheckRuns(beef, "public static int Count = 0x1F'FF; // the count", ref state,
			"keyword:public keyword:static type:int operator:= number:0x1F'FF punctuation:; comment:// the count");
		CheckRuns(beef, "defer { delete scope:: x; }", ref state,
			"keyword:defer punctuation:{ keyword:delete keyword:scope punctuation::: punctuation:; punctuation:}");
		CheckRuns(beef, "let n = 1'000'000 + 2.5f + 0b1010;", ref state,
			"keyword:let operator:= number:1'000'000 operator:+ number:2.5f operator:+ number:0b1010 punctuation:;");
		CheckRuns(beef, "s = $\"n{n + 1}{{x}}!\";", ref state,
			"operator:= string:$\"n punctuation:{ operator:+ number:1 punctuation:} escape:{{ string:x escape:}} string:!\" punctuation:;");
		CheckRuns(beef, "s = @\"C:\\a\"\"b\" + \"q\\\"r\";", ref state,
			"operator:= string:@\"C:\\a escape:\"\" string:b\" operator:+ string:\"q escape:\\\" string:r\" punctuation:;");
		CheckRuns(beef, "char8 c = '\\n';", ref state, "type:char8 operator:= string:' escape:\\n string:' punctuation:;");
		Test.Assert(state.Depth == 0);

		CheckRuns(beef, "/* a /* nested */ still", ref state, "comment:/* a /* nested */ still");
		Test.Assert(state.Depth == 1, "the outer comment goes on");
		CheckRuns(beef, "end */ bool b = true;", ref state, "comment:end */ type:bool operator:= constant:true punctuation:;");
		Test.Assert(state.Depth == 0);

		CheckRuns(beef, "let text = \"\"\"", ref state, "keyword:let operator:= string:\"\"\"");
		Test.Assert(state.Depth == 1, "a multi-line string goes on");
		CheckRuns(beef, "\tline \\t", ref state, "string:\tline  escape:\\t");
		CheckRuns(beef, "\t\"\"\";", ref state, "string:\t\"\"\" punctuation:;");
		Test.Assert(state.Depth == 0);

		CheckRuns(beef, "\t[Test(Name=\"x\"), AlwaysInclude]", ref state,
			"punctuation:[ attribute:Test punctuation:( operator:= string:\"x\" punctuation:), attribute:AlwaysInclude punctuation:]");
		CheckRuns(beef, "list[0] = null;", ref state, "punctuation:[ number:0 punctuation:] operator:= constant:null punctuation:;");
		CheckRuns(beef, "#if DEBUG", ref state, "preprocessor:#if DEBUG");
		Test.Assert(state.Depth == 0);
	}
}
