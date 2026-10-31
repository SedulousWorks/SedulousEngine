using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// The sprites' view block, mirroring sprite.vs.hlsl's SpriteView: the view's two matrices.
[CRepr]
struct GpuSpriteView
{
	public Float4x4 ViewProj;
	public Float4x4 View;
}
