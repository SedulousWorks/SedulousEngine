namespace Sedulous.Renderer.Probes;

using Sedulous.Core.Mathematics;
using Sedulous.Renderer;

/// Render data for a reflection probe. Not drawn — consumed by the probe
/// capture system to determine which probes need cubemap capture this frame.
///
/// Allocated from RenderContext.FrameAllocator — trivially destructible.
public class ReflectionProbeRenderData : RenderData
{
	/// World-space position of the probe.
	public Vector3 ProbePosition;

	/// Capture update mode (0=OnLoad, 1=EveryFrame, 2=Manual).
	public uint8 UpdateMode;

	/// Cubemap face resolution.
	public uint16 CaptureResolution;

	/// Near clip plane for probe camera.
	public float NearClip;

	/// Far clip plane for probe camera.
	public float FarClip;

	/// Influence radius for blending.
	public float InfluenceRadius;

	/// Intensity multiplier.
	public float Intensity;

	/// Opaque key identifying this probe (entity index + generation, cast to uint64).
	/// Used to look up per-probe GPU resources in the probe resource map.
	public uint64 ProbeKey;
}
