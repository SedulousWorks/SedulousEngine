using System;
using System.Collections;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Script.AngelScript;

namespace Sedulous.Editor.Script.Tests;

/// The AngelScript lexer registration and its tokens.
class AngelScriptEditorUITests
{
	[Test]
	public static void LexerRegistration()
	{
		AngelScriptEditorUI.Register();
		let byExtension = CodeLexerRegistry.Create("as");
		Test.Assert(byExtension != null);
		delete byExtension;
		let lexer = CodeLexerRegistry.Create("angelscript");
		Test.Assert(lexer != null);
		defer delete lexer;
		let tokens = scope List<CodeToken>();
		lexer.LexLine("int Update(float dt) override", 0, tokens);
		Test.Assert(tokens.Count >= 6);
		Test.Assert(tokens[0].Kind == .Type); // int
		Test.Assert(tokens[1].Kind == .Default); // Update
		bool sawKeyword = false;
		for (let token in tokens)
			sawKeyword = sawKeyword || (token.Kind == .Keyword);
		Test.Assert(sawKeyword);
		tokens.Clear();
		// Block comments do not nest: the first close ends it.
		Test.Assert(lexer.LexLine("/* a /* b */ done", 0, tokens) == 0);
	}
}
