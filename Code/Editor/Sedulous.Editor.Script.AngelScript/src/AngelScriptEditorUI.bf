using System;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Script.AngelScript;

/// The AngelScript side of the script editor: its lexer, registered under the language id
/// and its extension.
static class AngelScriptEditorUI
{
	private static readonly StringView[49] cKeywords = .(
		"abstract", "and", "auto", "break", "case", "cast", "class", "const", "continue", "default",
		"delete", "do", "else", "enum", "explicit", "external", "false", "final", "for", "from",
		"funcdef", "function", "get", "if", "import", "in", "inout", "interface", "is", "mixin",
		"namespace", "not", "null", "or", "out", "override", "private", "property", "protected",
		"return", "set", "shared", "super", "switch", "this", "true", "typedef", "while", "xor");
	private static readonly StringView[19] cTypes = .(
		"any", "array", "bool", "dictionary", "double", "float", "int", "int16", "int32", "int64",
		"int8", "ref", "string", "uint", "uint16", "uint32", "uint64", "uint8", "void");

	/// The caller owns the result.
	public static ICodeLexer MakeLexer()
	{
		var spec = CLikeLexerSpec();
		spec.Keywords = cKeywords;
		spec.Types = cTypes;
		spec.TripleQuotedStrings = true;
		spec.CharLiterals = true;
		return new CLikeLexer(spec);
	}

	public static void Register()
	{
		CodeLexerRegistry.Register("angelscript", new () => MakeLexer());
		CodeLexerRegistry.Register("as", new () => MakeLexer());
	}
}
