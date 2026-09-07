namespace Sedulous.RHI;

/// How the two weighted sides of a blend are combined.
enum BlendOperation : uint32
{
	Add,
	Subtract,
	ReverseSubtract,
	Min,
	Max
}
