using System;

namespace Sedulous.UI.Toolkit;

/// What varies between the C-shaped languages, so ONE lexer serves all of them.
///
/// The toolkit ships NO language tables: a module that owns a language supplies its own
/// keywords and types. That is what keeps the toolkit from growing a list per language it will
/// never be able to keep current.
struct CLikeLexerSpec
{
	/// BORROWED on the way in; the lexer copies them.
	public Span<StringView> Keywords = default;
	public Span<StringView> Types = default;

	/// Whether a block comment inside a block comment opens a second one.
	public bool NestedBlockComments = false;
	/// Triple quoted strings, which some scripting dialects use for heredocs.
	public bool TripleQuotedStrings = false;
	/// A line whose first visible character is a hash is one preprocessor token.
	public bool HashPreprocessorLines = false;
	/// Single quoted character literals.
	public bool CharLiterals = false;

	public this() {}
}
