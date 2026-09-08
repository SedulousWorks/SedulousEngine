using System;
using Sedulous.VG;

namespace Sedulous.VG.Renderer;

/// The vertex the vector graphics shader reads.
///
/// The colour passes through UNCONVERTED. Vertex colours are authored in sRGB and the
/// vertex shader does the single decode to linear; converting here as well would decode
/// twice.
[CRepr]
struct VGRenderVertex
{
	public float[2] Position;
	public float[2] TexCoord;
	public float[4] Color;
	public float Coverage;

	/// The stride the vertex layout declares.
	public const int SizeInBytes = 36;

	public this()
	{
		Position = .(0, 0);
		TexCoord = .(0, 0);
		Color = .(1, 1, 1, 1);
		Coverage = 1.0f;
	}

	public this(VGVertex vertex)
	{
		Position = .(vertex.Position.X, vertex.Position.Y);
		TexCoord = .(vertex.TexCoord.X, vertex.TexCoord.Y);
		Color = .(vertex.Color.R, vertex.Color.G, vertex.Color.B, vertex.Color.A);
		Coverage = vertex.Coverage;
	}
}
