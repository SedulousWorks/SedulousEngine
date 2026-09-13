using System;
using Sedulous.Core;

namespace Sedulous.Engine.Particles;

/// One ribbon vertex: a world position, a coordinate and a colour, already oriented toward the
/// camera by the extractor.
///
/// The trail path draws these as a plain triangle list. There is nothing to instance: the
/// geometry is per particle and already built.
[CRepr]
struct TrailVertex
{
	public Float3 Position = .(0.0f, 0.0f, 0.0f);
	public Float2 TexCoord = .(0.0f, 0.0f);
	public Float4 Color = .(1.0f, 1.0f, 1.0f, 1.0f);

	public this() {}
}
