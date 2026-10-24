using System;
using System.Collections;
using Sedulous.Image;
using Sedulous.VG.SVG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// IResourceProvider: the seam the CSS engine uses to load image assets referenced by
// background-image: url(path). It returns a raw, provider-owned image (not a framework Drawable),
// so the provider stays a pure asset loader (VFS + Sedulous.Image) with no dependency on the GUI's
// drawable types; the StyleApplier wraps the image into an ImageDrawable. Font resolution is a
// separate seam (IFontProvider). An SVG may also be written inline, as a `data:image/svg+xml,...`
// URL (its markup percent-encoded or plain, or base64 after `;base64`): the provider parses it
// once and keeps it as it keeps a named one, so a box borrows either for as long as the provider
// lives.

/// An abstract class, not an interface: it keeps the inline SVGs it has parsed.
abstract class IResourceProvider
{
	/// An inline SVG by its source, and its document (null: it did not parse).
	private class InlineSvg
	{
		public String Source = new .() ~ delete _;
		public SVGDocument Document ~ delete _;
	}

	private List<InlineSvg> mInline = new .() ~ DeleteContainerAndItems!(_);

	/// Load image data for a path (background-image: url(path)). Returns a borrowed image owned
	/// by the provider (valid until the provider releases it), or null if not found.
	public abstract ImageData LoadImage(StringView path);
	/// A text file's contents (a sheet's @import): true and the contents appended to `outText`
	/// when it is there.
	public abstract bool LoadText(StringView path, String outText);
	/// An SVG picture by its path (a CSS image whose path ends in .svg): a borrowed document the
	/// provider keeps (parsed once), drawn as paths at whatever size it fills; null if not found.
	/// Callers ask Svg, which answers an inline one itself.
	public abstract SVGDocument LoadSvg(StringView path);

	/// An SVG picture by its source: one written inline (a data: URL) parsed the first time and
	/// kept here, any other through LoadSvg. Borrowed; null when there is none (an inline one
	/// that does not parse is remembered as none).
	public SVGDocument Svg(StringView source)
	{
		if (!IsSvgDataUrl(source))
			return LoadSvg(source);
		for (let known in mInline)
			if (known.Source == source)
				return known.Document;
		let entry = new InlineSvg();
		entry.Source.Set(source);
		let markup = scope String();
		if (DecodeSvgDataUrl(source, markup))
			if (SVGLoader.Load(markup) case .Ok(let document))
				entry.Document = document;
		mInline.Add(entry);
		return entry.Document;
	}
}

static
{
	/// Whether `source` is an SVG written inline: a `data:image/svg+xml` URL.
	public static bool IsSvgDataUrl(StringView source)
	{
		StringView prefix = "data:image/svg+xml";
		return ResourceProviderDetail.StartsWithNoCase(source, prefix) && (source.Length > prefix.Length) &&
			((source[prefix.Length] == ',') || (source[prefix.Length] == ';'));
	}

	/// The SVG markup a `data:image/svg+xml[;param]*[;base64],payload` URL carries, appended to
	/// `outText`; false when `source` is not one or its payload does not decode, and then
	/// `outText` is left as it was.
	public static bool DecodeSvgDataUrl(StringView source, String outText)
	{
		if (!IsSvgDataUrl(source))
			return false;
		int comma = 0;
		while ((comma < source.Length) && (source[comma] != ','))
			comma++;
		if (comma == source.Length)
			return false;
		let header = source.Substring(0, comma);
		let payload = source.Substring(comma + 1, source.Length - comma - 1);
		StringView base64Param = ";base64";
		let base64 = (header.Length >= base64Param.Length) &&
			ResourceProviderDetail.StartsWithNoCase(header.Substring(header.Length - base64Param.Length, base64Param.Length), base64Param);
		if (!base64)
		{
			ResourceProviderDetail.DecodePercent(payload, outText);
			return true;
		}
		let unescaped = scope String(); // base64 may itself be percent-encoded (its '+', '/' and '=')
		ResourceProviderDetail.DecodePercent(payload, unescaped);
		let start = outText.Length;
		if (ResourceProviderDetail.DecodeBase64(unescaped, outText))
			return true;
		outText.RemoveToEnd(start);
		return false;
	}

	/// Whether a picture's source is an SVG: a path ending in .svg (either case), or one written
	/// inline (IsSvgDataUrl). Drawn as paths, not loaded as a raster.
	public static bool IsSvgSource(StringView source)
	{
		if (IsSvgDataUrl(source))
			return true;
		if (source.Length <= 4)
			return false;
		let end = source.Substring(source.Length - 4, 4);
		return (end == ".svg") || (end == ".SVG");
	}
}

/// The data: URL decoding ResourceProvider.bf keeps out of the public surface.
internal static class ResourceProviderDetail
{
	public static char8 LowerAscii(char8 c) => ((c >= 'A') && (c <= 'Z')) ? (char8)((uint8)c + 32) : c;

	public static bool StartsWithNoCase(StringView s, StringView prefix)
	{
		if (s.Length < prefix.Length)
			return false;
		for (int i = 0; i < prefix.Length; i++)
			if (LowerAscii(s[i]) != LowerAscii(prefix[i]))
				return false;
		return true;
	}

	public static int32 Base64Value(char8 c)
	{
		if ((c >= 'A') && (c <= 'Z'))
			return (int32)c - (int32)'A';
		if ((c >= 'a') && (c <= 'z'))
			return (int32)c - (int32)'a' + 26;
		if ((c >= '0') && (c <= '9'))
			return (int32)c - (int32)'0' + 52;
		if ((c == '+') || (c == '-'))
			return 62;
		if ((c == '/') || (c == '_'))
			return 63;
		return -1;
	}

	/// `%XX` escapes decoded; a `%` not followed by two hex digits is kept as it is.
	public static void DecodePercent(StringView input, String outText)
	{
		for (int i = 0; i < input.Length; i++)
		{
			let hi = ((input[i] == '%') && (i + 2 < input.Length)) ? ParseUtil.HexValue(input[i + 1]) : -1;
			let lo = (hi >= 0) ? ParseUtil.HexValue(input[i + 2]) : -1;
			if (lo >= 0)
			{
				outText.Append((char8)(uint8)(hi * 16 + lo));
				i += 2;
			}
			else
				outText.Append(input[i]);
		}
	}

	/// Base64 (either alphabet, white space and padding skipped), appended; false on any other
	/// character.
	public static bool DecodeBase64(StringView input, String outText)
	{
		uint32 bits = 0;
		int32 count = 0;
		for (let c in input.RawChars)
		{
			if ((c == '=') || (c == ' ') || (c == '\n') || (c == '\r') || (c == '\t'))
				continue;
			let v = Base64Value(c);
			if (v < 0)
				return false;
			bits = (bits << 6) | (uint32)v;
			count += 6;
			if (count >= 8)
			{
				count -= 8;
				outText.Append((char8)(uint8)((bits >> count) & 0xFF));
			}
		}
		return true;
	}
}
