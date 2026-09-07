namespace Sedulous.RHI;

/// The test a depth, stencil or comparison sampler applies. The named side is the INCOMING
/// value: Less passes when the new fragment is nearer than what is stored.
enum CompareFunction : uint32
{
	Never,
	Less,
	Equal,
	LessEqual,
	Greater,
	NotEqual,
	GreaterEqual,
	Always
}
