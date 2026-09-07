namespace Sedulous.RHI;

/// What each side of a blend equation is multiplied by.
///
/// Src is the incoming fragment and Dst is what is already in the target. Constant reads
/// the value set by SetBlendConstant, which is why that is a pass level command rather
/// than pipeline state.
enum BlendFactor : uint32
{
	Zero,
	One,
	Src,
	OneMinusSrc,
	SrcAlpha,
	OneMinusSrcAlpha,
	Dst,
	OneMinusDst,
	DstAlpha,
	OneMinusDstAlpha,
	SrcAlphaSaturated,
	Constant,
	OneMinusConstant
}
