namespace Sedulous.VG.Backend.Tests;

/// Which RHI backend a VG probe fixture builds its device on.
///
/// The vector path is stencil heavy: a stencil then cover fill, a clip pushed as a stencil
/// mask, and a multisample resolve over hard edges. Those are exactly the places where two
/// backends can be configured differently and still each look plausible on its own, so every
/// pixel case runs on every one of them rather than trusting a single backend.
enum ProbeBackend
{
	Vulkan,
	WebGpu,
	/// DX12, which only exists on Windows. The fixture answers NOT READY for it elsewhere, so
	/// every probe that iterates this list skips it on other platforms without a guard of its
	/// own.
	Dx12
}
