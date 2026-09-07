namespace Sedulous.RHI;

/// Which channels a colour target actually writes.
///
/// Backed by a byte rather than a word because that is what the hardware descriptor holds,
/// and it is stored per colour target in a pipeline.
enum ColorWriteMask : uint8
{
	case None = 0;
	case Red = 1;
	case Green = 2;
	case Blue = 4;
	case Alpha = 8;
	case All = Red | Green | Blue | Alpha;
}
