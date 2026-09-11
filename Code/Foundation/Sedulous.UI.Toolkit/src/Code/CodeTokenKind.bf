namespace Sedulous.UI.Toolkit;

/// What a run of characters IS, which is all the renderer needs: the theme maps each kind to a
/// colour and nothing downstream knows about any particular language.
enum CodeTokenKind : uint8
{
	/// Identifiers and plain text, drawn in the theme's ordinary text colour.
	Default,
	Keyword,
	/// A builtin or primitive type name.
	Type,
	Number,
	String,
	Comment,
	Operator,
	Punctuation,
	/// A hash line in a shader, an XML declaration.
	Preprocessor,
	/// An XML element name.
	Tag,
	/// An XML attribute name.
	Attribute
}
