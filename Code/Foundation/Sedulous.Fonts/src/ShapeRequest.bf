using System;

namespace Sedulous.Fonts;

/// What to shape: text in a list of fonts (a character takes the first font that has its glyph;
/// one no font has takes the first), read in a direction, as a script and a language. The shaper
/// splits the text into runs where the font or the script changes.
struct ShapeRequest
{
	public StringView Text;
	/// In order of preference. BORROWED.
	public Span<IFont> Fonts;
	public TextDirection Direction = .Auto;
	/// An ISO 15924 script tag (ScriptTag("Arab"), ScriptTag("Latn"), ...), 0 to find each run's
	/// from its characters.
	public uint32 Script = 0;
	/// A BCP 47 language ("sr", "ar"), empty for none: a font may draw some characters as that
	/// language writes them (a Serbian be).
	public StringView Language = default;
	public float StartX = 0;
	public float StartY = 0;

	/// A request for `text` in `fonts`.
	public this(StringView text, Span<IFont> fonts)
	{
		Text = text;
		Fonts = fonts;
	}

	/// An ISO 15924 script tag from its four letters ("Arab" to 'Arab').
	public static uint32 ScriptTag(StringView letters)
	{
		if (letters.Length != 4)
			return 0;
		return ((uint32)(uint8)letters[0] << 24) | ((uint32)(uint8)letters[1] << 16)
			| ((uint32)(uint8)letters[2] << 8) | (uint32)(uint8)letters[3];
	}
}
