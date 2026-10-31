using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// What the debug geometry pushes, mirroring debug_geom.vs.hlsl's GeomPush: the view's matrix.
[CRepr]
struct DebugGeomPush
{
	public Float4x4 ViewProj = .Identity();

	public this() {}
}

/// What the debug screen overlay pushes, mirroring debug_screen.vs.hlsl's ScreenPush: one over
/// the viewport's size, padded to 16 bytes.
[CRepr]
struct DebugScreenPush
{
	public Float2 InvSize = .(0, 0);
	public Float2 Pad = .(0, 0);

	public this() {}
}
