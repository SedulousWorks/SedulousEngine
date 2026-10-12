using System;
using System.Collections;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Shaders;

namespace Sedulous.Editor.Shaders.Tests;

/// The HLSL lexer: its registration, and the tokens a shader is highlighted by.
class HlslLexerTests
{
	private static void Kinds(ICodeLexer lexer, StringView line, List<CodeTokenKind> outKinds)
	{
		let tokens = scope List<CodeToken>();
		lexer.LexLine(line, 0, tokens);
		for (let token in tokens)
			outKinds.Add(token.Kind);
	}

	[Test]
	public static void RegisteredUnderHlslAndHlsliCaseInsensitively()
	{
		HlslEditorUI.Register();
		let hlsl = CodeLexerRegistry.Create("hlsl");
		Test.Assert(hlsl != null);
		delete hlsl;
		let hlsli = CodeLexerRegistry.Create("HLSLI");
		Test.Assert(hlsli != null);
		delete hlsli;
	}

	[Test]
	public static void TypesKeywordsNumbersCommentsAndPreprocessorLines()
	{
		HlslEditorUI.Register();
		let lexer = CodeLexerRegistry.Create("hlsl");
		Test.Assert(lexer != null);
		defer delete lexer;

		let declaration = scope List<CodeTokenKind>();
		Kinds(lexer, "float4 PSMain(VSOutput input) : SV_Target0 {", declaration);
		Test.Assert((declaration.Count >= 2) && (declaration[0] == .Type) && (declaration[1] == .Default));

		let body = scope List<CodeTokenKind>();
		Kinds(lexer, "if (c.a < 0.5) discard; // cut out", body);
		Test.Assert(body[0] == .Keyword);
		Test.Assert(body.Contains(.Number));
		Test.Assert(body[body.Count - 1] == .Comment);

		// A '#' line is one token, even indented.
		let include = scope List<CodeTokenKind>();
		Kinds(lexer, "  #include \"lighting.hlsli\"", include);
		Test.Assert((include.Count == 1) && (include[0] == .Preprocessor));

		// Resources and the properties block's own types are types; `properties` is a keyword.
		let one = scope List<CodeTokenKind>();
		Kinds(lexer, "Texture2D", one..Clear());
		Test.Assert(one[0] == .Type);
		Kinds(lexer, "Color", one..Clear());
		Test.Assert(one[0] == .Type);
		Kinds(lexer, "properties", one..Clear());
		Test.Assert(one[0] == .Keyword);

		// Block comments do not nest: the first terminator closes, and the state carries over
		// lines.
		let tokens = scope List<CodeToken>();
		Test.Assert(lexer.LexLine("/* a /* b */ done", 0, tokens) == 0);
		tokens.Clear();
		Test.Assert(lexer.LexLine("/* open", 0, tokens) != 0);
	}
}
