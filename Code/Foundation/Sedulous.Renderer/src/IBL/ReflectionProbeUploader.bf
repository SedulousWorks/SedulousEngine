namespace Sedulous.Renderer.IBL;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// GPU-packed reflection probe data. Layout matches the HLSL StructuredBuffer
/// stride declared in RenderContext.CreateBindGroupLayouts (set 0 t3).
/// Field order is locked in - shader code in Sub-phase F reads it positionally.
[CRepr]
public struct GPUReflectionProbe
{
	public Vector3 Position;
	public float InfluenceRadius;
	public Vector3 BoxMin;
	public float Padding0;
	public Vector3 BoxMax;
	public int32 SHCoeffStart;
	public int32 CubemapLayer;
	public int32 Enabled;
	public int32 PrefilterMipCount;
	public float BlendEdge;

	/// Byte size (must match RenderContext.ProbeStride and StructuredBufferStride).
	public const int Size = 64;
}

/// Packs extracted ReflectionProbeRenderData into the per-frame
/// StructuredBuffer<GPUReflectionProbe> at set 0 t3.
public static class ReflectionProbeUploader
{
	/// Walks the ExtractedRenderData's reflection probe entries and writes the
	/// per-probe GPU data into `probeBuffer`. Returns the count of active probes
	/// uploaded (used by the shader as the upper bound of its per-pixel probe
	/// loop). Disabled / out-of-slot probes are silently skipped.
	public static int32 Upload(ExtractedRenderData data, IBuffer probeBuffer)
	{
		if (data == null || probeBuffer == null) return 0;

		let probes = data.GetBatch(RenderCategories.ReflectionProbe);

		GPUReflectionProbe[RenderContext.MaxIBLProbes] gpu = default;
		int32 activeCount = 0;

		if (probes != null)
		{
			for (let entry in probes)
			{
				if (activeCount >= RenderContext.MaxIBLProbes) break;
				let probe = entry as ReflectionProbeRenderData;
				if (probe == null) continue;
				if (probe.ArraySlot < 0) continue;

				gpu[activeCount] = .()
				{
					Position = probe.ProbePosition,
					InfluenceRadius = probe.InfluenceRadius,
					BoxMin = probe.LocalBoxMin,
					Padding0 = 0,
					BoxMax = probe.LocalBoxMax,
					SHCoeffStart = probe.ArraySlot * RenderContext.IBLSH9CoeffPerProbe,
					CubemapLayer = probe.ArraySlot * 6,
					Enabled = 1,
					PrefilterMipCount = RenderContext.IBLPrefilterMipCount,
					BlendEdge = probe.BlendEdge
				};
				activeCount++;
			}
		}

		// Always upload the full buffer so previously-disabled slots reset to
		// zero (Enabled = 0 in the default-constructed gpu[] entries).
		TransferHelper.WriteMappedBuffer(probeBuffer, 0,
			Span<uint8>((uint8*)&gpu[0], GPUReflectionProbe.Size * RenderContext.MaxIBLProbes));

		return activeCount;
	}
}
