namespace Sedulous.VG.Backend.Tests;

/// Which RHI backend a VG probe fixture builds its device on.
///
/// The vector path is stencil heavy: a stencil then cover fill, a clip pushed as a stencil
/// mask, and a multisample resolve over hard edges. Those are exactly the places where two
/// backends can be configured differently and still each look plausible on its own, so every
/// pixel case runs on both rather than trusting one.
enum ProbeBackend
{
	Vulkan,
	WebGpu
}
