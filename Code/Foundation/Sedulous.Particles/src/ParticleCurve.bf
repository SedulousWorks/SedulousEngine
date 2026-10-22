namespace Sedulous.Particles;

/// What every particle curve shares: its fixed size.
///
/// FIXED at eight keys rather than a list, because a curve is a VALUE that lives inside a
/// system's settings: a heap allocation per curve would put an indirection on the spawn path
/// and make copying a system's settings a deep copy.
///
/// The curves are of Core's types and sampled by Core's functions (EvaluateCurve,
/// EvaluateGradient), so an editor drawing with the same functions shows what plays.
static class ParticleCurve
{
	public const int32 MaxKeys = 8;
}
