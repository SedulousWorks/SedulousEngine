namespace Sedulous.Render.Backend.Tests;

/// Which RHI backend a probe fixture builds its device on.
///
/// Vulkan is the REFERENCE: the orientation case asserts its halves against Vulkan's numbers
/// rather than against constants, so a deliberate change to the lighting moves both together
/// and only a real divergence fails.
///
/// WebGpu is the DESKTOP WebGPU backend. Running the same frame through it is what catches the
/// whole vertical flip class at its source: a naga cook missing keep-coordinate-space mirrors
/// the scene, and a front face winding hack culls the plane to black. Neither shows on Vulkan.
enum ProbeBackend
{
	Vulkan,
	WebGpu
}
