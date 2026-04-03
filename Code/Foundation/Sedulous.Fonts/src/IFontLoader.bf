using System;

namespace Sedulous.Fonts;

/// Interface for font loaders (backend implementations)
public interface IFontLoader
{
	/// File extensions this loader supports (e.g., ".ttf", ".otf")
	Span<StringView> SupportedExtensions { get; }

	/// Check if this loader supports the given file extension
	bool SupportsExtension(StringView fileExtension);

	/// Load font from file path
	Result<IFont, FontLoadResult> LoadFromFile(StringView filePath, FontLoadOptions options);

	/// Load font from memory
	Result<IFont, FontLoadResult> LoadFromMemory(Span<uint8> data, FontLoadOptions options);

	/// Create a font atlas for a loaded font
	Result<IFontAtlas, FontLoadResult> CreateAtlas(IFont font, FontLoadOptions options);
}
