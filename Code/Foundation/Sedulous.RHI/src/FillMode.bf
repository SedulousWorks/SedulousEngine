namespace Sedulous.RHI;

/// Solid or wireframe. Wireframe is not universal, so a pipeline asking for it should
/// check the device's feature set first.
enum FillMode : uint32
{
	Solid,
	Wireframe
}
