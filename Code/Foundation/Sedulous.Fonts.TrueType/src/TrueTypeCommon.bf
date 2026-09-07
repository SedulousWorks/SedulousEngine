using System;

namespace Sedulous.Fonts.TrueType;

/// What this backend claims, and how it compares an extension.
static class TrueTypeCommon
{
	/// The identity a baker checks to recognise a font this parser produced.
	///
	/// Beef has real type tests, so a baker could ask `font is TrueTypeFont` instead.
	/// The tag is kept because IFont.BackendTypeId is the seam's own contract: a backend
	/// living in another library, loaded as a plugin, is matched by id and not by a type
	/// the host was compiled against.
	public const uint32 BackendTypeId = 0x54545446; // 'TTF' with a trailing F.

	private static StringView[3] sExtensions = .(".ttf", ".ttc", ".otf");

	/// The formats stb_truetype reads: TrueType, a TrueType collection, and OpenType.
	public static Span<StringView> Extensions => .(&sExtensions[0], 3);

	/// Extensions arrive from a path in whatever case the filesystem had.
	public static bool EqualsIgnoreCase(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (a[i].ToLower != b[i].ToLower)
				return false;
		}
		return true;
	}

	public static bool IsSupportedExtension(StringView fileExtension)
	{
		for (let candidate in Extensions)
		{
			if (EqualsIgnoreCase(fileExtension, candidate))
				return true;
		}
		return false;
	}
}
