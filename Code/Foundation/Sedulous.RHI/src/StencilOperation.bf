namespace Sedulous.RHI;

/// What happens to the stored stencil value at each outcome of the test.
enum StencilOperation : uint32
{
	Keep,
	Zero,
	Replace,
	IncrementClamp,
	DecrementClamp,
	Invert,
	IncrementWrap,
	DecrementWrap
}
