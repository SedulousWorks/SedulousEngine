namespace Sedulous.Fonts;

/// Result codes for font loading operations
public enum FontLoadResult
{
	Success,
	FileNotFound,
	InvalidFormat,
	UnsupportedFormat,
	CorruptedData,
	OutOfMemory,
	NoGlyphsFound,
	AtlasPackingFailed,
	Unknown
}
