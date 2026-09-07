namespace Sedulous.RHI;

/// What kind of shader group an entry in a ray tracing pipeline is.
enum RayTracingShaderGroupType : uint32
{
	/// A standalone shader: ray generation, miss, or callable.
	General,
	/// A hit group over triangle geometry, with no intersection shader: the fixed function
	/// triangle test provides the hit.
	TrianglesHitGroup,
	/// A hit group over procedural geometry, where an intersection shader provides the hit.
	ProceduralHitGroup
}
