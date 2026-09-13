namespace Sedulous.Geometry.Pipeline;

/// How far automatic level of detail generation goes.
///
/// The ratios are a halving ladder. A level is DROPPED, and the chain ends there, when
/// simplification cannot get near its target within the error bound: a chain is as long as
/// quality allows and is never padded out to a fixed length.
struct LodGenerationSettings
{
	/// The simplifier's relative error bound, as a fraction of the mesh's extent.
	public float TargetError = 0.02f;
	/// Stop once a level would fall below this, there being no point simplifying a tiny mesh
	/// further.
	public uint32 MinTriangles = 64;

	public this() {}
}
