namespace Sedulous.Model;

/// Why a model load did or did not work.
enum ModelLoadResult : uint32
{
	case Ok;
	case FileNotFound;
	case ParseError;
	case UnsupportedFormat;
	case OutOfMemory;
	case InvalidData;
}
