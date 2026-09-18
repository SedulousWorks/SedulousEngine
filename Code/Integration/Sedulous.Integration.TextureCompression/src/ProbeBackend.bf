namespace Sedulous.Integration.TextureCompression;

/// Which RHI backend the probe builds its device on.
///
/// Block compression is where backends most plausibly differ: each decodes the formats in its
/// own driver, and each has its own idea of how a compressed upload's row pitch is counted. So
/// every case runs on every backend rather than on one.
enum ProbeBackend
{
	Vulkan,
	WebGpu,
	/// Windows only. The fixture answers NOT READY elsewhere, so the loops skip it.
	Dx12
}
