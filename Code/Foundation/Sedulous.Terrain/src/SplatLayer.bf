namespace Sedulous.Terrain;

/// One splat layer's PURE parameters.
///
/// The material and texture references live on the resource side; what is here is only what
/// the model needs to reason about.
struct SplatLayer
{
	/// How many times the layer's texture repeats across the WHOLE terrain.
	public float TileScale = 1.0f;

	public this() {}
}
