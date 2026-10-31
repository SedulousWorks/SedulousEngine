using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// One colour per token kind. [[CodeTokenKind]].Default always draws in the theme's text
/// colour, so a page that only wants plain text does not have to restyle anything.
///
/// A plain field on [[CodeEditView]] rather than a style sheet: syntax colours are a PALETTE
/// picked as a set, and the defaults below are tuned for the dark editor themes.
struct CodeTokenColors
{
	public Color Keyword = Color.Rgb(235, 155, 90);
	public Color Type = Color.Rgb(86, 182, 194);
	public Color Number = Color.Rgb(220, 190, 120);
	public Color String = Color.Rgb(152, 195, 121);
	public Color Comment = Color.Rgb(110, 120, 130);
	public Color Operator = Color.Rgb(170, 178, 190);
	public Color Punctuation = Color.Rgb(150, 158, 170);
	public Color Preprocessor = Color.Rgb(198, 120, 221);
	public Color Tag = Color.Rgb(97, 175, 239);
	public Color Attribute = Color.Rgb(229, 192, 123);

	public this() {}

	public Color For(CodeTokenKind kind, Color defaultColor)
	{
		switch (kind)
		{
		case .Keyword: return Keyword;
		case .Type: return Type;
		case .Number: return Number;
		case .String: return String;
		case .Comment: return Comment;
		case .Operator: return Operator;
		case .Punctuation: return Punctuation;
		case .Preprocessor: return Preprocessor;
		case .Tag: return Tag;
		case .Attribute: return Attribute;
		default: return defaultColor;
		}
	}
}
