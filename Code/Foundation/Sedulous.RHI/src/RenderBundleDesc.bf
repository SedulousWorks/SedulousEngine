using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// A render bundle's TARGET SIGNATURE, so it can be validated against, and replayed into,
/// the passes it is compatible with.
///
/// A bundle records draws without a pass, so it has to state up front what it records for:
/// the attachment formats and sample count a pass must match.
struct RenderBundleDesc
{
	public TextureFormat[RhiLimits.MaxColorAttachments] ColorFormats = .(.Undefined,);
	public uint32 ColorFormatCount = 0;
	public TextureFormat DepthStencilFormat = .Undefined;

	/// Whether the bundle leaves the aspect unwritten. WebGPU VALIDATES these against the
	/// executing pass, a read only pass accepting only read only bundles; Vulkan and DX12
	/// bundles carry no such state and ignore them.
	public bool DepthReadOnly = false;
	public bool StencilReadOnly = false;

	public uint32 SampleCount = 1;

	/// The bundle's own viewport and scissor, being a sub rectangle of the target for
	/// something like split screen. A Vulkan secondary or a DX12 bundle records this up
	/// front, since it cannot inherit the parent pass's dynamic viewport state.
	public int32 ViewportX = 0;
	public int32 ViewportY = 0;
	public uint32 Width = 0;
	public uint32 Height = 0;
	public StringView Label = default;

	public this() {}
}
