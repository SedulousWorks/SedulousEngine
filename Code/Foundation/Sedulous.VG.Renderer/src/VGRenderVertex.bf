using System;
using Sedulous.VG;

namespace Sedulous.VG.Renderer;

/// The vertex the vector graphics shader reads.
///
/// The colour passes through UNCONVERTED. Vertex colours are authored in sRGB and the
/// vertex shader does the single decode to linear; converting here as well would decode
/// twice.
///
/// The fields keep VGVertex's names; two pipelines read TexCoord, Coverage and Effect for other
/// values (VGVertex's comment and named constructors list them, and each fragment shader names
/// its inputs for its own meaning).
[CRepr]
struct VGRenderVertex
{
	public float[2] Position;
	/// The SDF operand for a box shadow.
	public float[2] TexCoord;
	public float[4] Color;
	/// The signed corner radius for a box shadow.
	public float Coverage;
	/// A glyph's edge shift and ramp; a layer's colour filter (VGVertex.Effect).
	public float[2] Effect;

	/// The stride the vertex layout declares: 8 + 8 + 16 + 4 + 8.
	public const int SizeInBytes = 44;

	public this()
	{
		Position = .(0, 0);
		TexCoord = .(0, 0);
		Color = .(1, 1, 1, 1);
		Coverage = 1.0f;
		Effect = .(0, 0);
	}

	public this(VGVertex vertex)
	{
		Position = .(vertex.Position.X, vertex.Position.Y);
		TexCoord = .(vertex.TexCoord.X, vertex.TexCoord.Y);
		Color = .(vertex.Color.R, vertex.Color.G, vertex.Color.B, vertex.Color.A);
		Coverage = vertex.Coverage;
		Effect = .(vertex.Effect.X, vertex.Effect.Y);
	}
}
