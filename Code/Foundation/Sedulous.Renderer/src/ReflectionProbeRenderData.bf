namespace Sedulous.Renderer;

using Sedulous.Core.Mathematics;

/// Render data for a reflection probe. Not drawn directly - consumed by the
/// IBL upload step (packs into the per-frame StructuredBuffer<GPUReflectionProbe>
/// at set 0 t3) and by the capture scheduler (Sub-phase C).
///
/// Allocated from RenderContext.FrameAllocator each frame - trivially destructible.
public class ReflectionProbeRenderData : RenderData
{
	/// Probe origin in world space (capture point).
	public Vector3 ProbePosition;
	/// Sphere influence radius. Fragment world-positions farther than this
	/// from ProbePosition contribute zero. Used together with the box bounds
	/// for the weighted blend.
	public float InfluenceRadius;
	/// Min corner of the local-space influence box.
	public Vector3 LocalBoxMin;
	/// Max corner of the local-space influence box.
	public Vector3 LocalBoxMax;
	/// Distance (world units) over which the probe contribution falls off
	/// from full at the box surface to zero at the influence radius.
	public float BlendEdge;
	/// Stable slot index assigned by ReflectionProbeManager at component
	/// creation. CubemapLayer == ArraySlot * 6 in the prefiltered cubemap
	/// array; SHCoeffStart == ArraySlot * 9 in the SH9 buffer.
	public int32 ArraySlot;
}
