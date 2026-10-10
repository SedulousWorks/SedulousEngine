using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The shader grid's push block, mirroring debug_grid.hlsli's GridPush: the view matrix,
/// then four float4s.
[CRepr]
struct GridPush
{
	public Float4x4 ViewProj = .Identity();
	/// The quad's centre on the plane, and its half size in metres.
	public Float4 OriginExtent = .(0, 0, 0, 0);
	/// The plane's first axis, and the finest line spacing in metres.
	public Float4 AxisUSpacing = .(0, 0, 0, 0);
	/// The plane's second axis, and how far toward the next decade.
	public Float4 AxisVBlend = .(0, 0, 0, 0);
	/// The camera, and the distance the grid has faded out by.
	public Float4 CameraFade = .(0, 0, 0, 0);

	public this() {}
}
