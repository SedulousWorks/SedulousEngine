using System;
using wgpu_Beef;

namespace Sedulous.RHI.WebGPU;

/// emdawnwebgpu's canvas surface source, which wgpu-native's headers do not declare.
///
/// The bindings in Dependencies/wgpu-Beef are generated from wgpu-native's webgpu.h and
/// wgpu.h, and this type exists in neither: it belongs to Dawn's emdawnwebgpu port, the
/// implementation a browser build links instead. So it is declared here, beside its one
/// user, rather than added to a generated file that a version bump would overwrite.
///
/// The sType value and the layout are taken verbatim from emdawnwebgpu's webgpu.h.
[CRepr]
struct WebGpuCanvasSurfaceSource
{
	/// WGPUSType_EmscriptenSurfaceSourceCanvasHTMLSelector.
	public const WGPUSType SType = (WGPUSType)0x00040000;

	public WGPUChainedStruct Chain;
	public WGPUStringView Selector;
}
