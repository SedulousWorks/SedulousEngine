namespace Sedulous.Fonts;

/// Why a font load did or did not work.
///
/// The failures are distinguished rather than collapsed because they call for different
/// responses: a missing file is a content problem, a packing failure means the atlas was
/// sized too small for the range asked for, and no glyphs found usually means the codepoint
/// range and the font do not overlap.
enum FontLoadResult
{
	case Success;
	case FileNotFound;
	case InvalidFormat;
	case UnsupportedFormat;
	case CorruptedData;
	case OutOfMemory;
	case NoGlyphsFound;
	case AtlasPackingFailed;
	case Unknown;
}
