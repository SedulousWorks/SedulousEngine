using System;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The vertex the tessellators emit.
class VGVertexTests
{
	/// The stride the renderer's vertex layout declares. If the struct grows without the
	/// layout following, every attribute after the change reads the wrong bytes.
	[Test]
	public static void TheStrideMatchesTheDeclaredSize()
	{
		Test.Assert(sizeof(VGVertex) == VGVertex.SizeInBytes);
		Test.Assert(VGVertex.SizeInBytes == 44, "two float2s, a float4 colour, a coverage and an effect float2");
	}

	/// The colour stays FLOAT end to end. Packing it to bytes quantised gradients and
	/// antialiased fringes for no GPU benefit, because the attribute re-expands anyway.
	[Test]
	public static void TheColourKeepsItsPrecision()
	{
		let vertex = VGVertex.Solid(.(0, 0), .(0.1f, 0.2f, 0.3f, 0.4f));
		Test.Assert(vertex.Color.R == 0.1f);
		Test.Assert(vertex.Color.G == 0.2f);
		Test.Assert(vertex.Color.B == 0.3f);
		Test.Assert(vertex.Color.A == 0.4f);
	}

	/// A solid vertex samples the middle of whatever is bound, so a solid draw needs no
	/// pipeline of its own.
	[Test]
	public static void ASolidVertexSamplesTheMiddle()
	{
		let vertex = VGVertex.Solid(.(3, 4), .Red);
		Test.Assert(vertex.Position == Float2(3, 4));
		Test.Assert(vertex.TexCoord.X == VGVertex.SolidUV);
		Test.Assert(vertex.TexCoord.Y == VGVertex.SolidUV);
		Test.Assert(vertex.Coverage == 1.0f, "opaque unless a fringe says otherwise");

		let byComponent = VGVertex.Solid(3, 4, .Red);
		Test.Assert(byComponent.Position == vertex.Position);
		Test.Assert(byComponent.TexCoord == vertex.TexCoord);
	}

	[Test]
	public static void ATexturedVertexKeepsItsCoordinatesAndCoverage()
	{
		let vertex = VGVertex(.(1, 2), .(0.25f, 0.75f), .Blue, 0.5f);
		Test.Assert(vertex.TexCoord == Float2(0.25f, 0.75f));
		Test.Assert(vertex.Coverage == 0.5f);

		let byComponent = VGVertex(1, 2, 0.25f, 0.75f, .Blue, 0.5f);
		Test.Assert(byComponent.Position == vertex.Position);
		Test.Assert(byComponent.TexCoord == vertex.TexCoord);
		Test.Assert(byComponent.Coverage == vertex.Coverage);
	}

	/// A default vertex is opaque white at the origin, which is what an uninitialised slot
	/// in a batch should look like rather than a transparent black hole.
	[Test]
	public static void TheDefaultIsOpaqueWhite()
	{
		let vertex = VGVertex();
		Test.Assert(vertex.Coverage == 1.0f);
		Test.Assert(vertex.Color == Color.White);
	}

	/// Every field where the renderer's vertex layout reads it (VGRenderer's attributes), the
	/// render vertex the same.
	[Test]
	public static void EachFieldSitsWhereTheLayoutReadsIt()
	{
		Test.Assert(offsetof(VGVertex, Position) == 0);
		Test.Assert(offsetof(VGVertex, TexCoord) == 8);
		Test.Assert(offsetof(VGVertex, Color) == 16);
		Test.Assert(offsetof(VGVertex, Coverage) == 32);
		Test.Assert(offsetof(VGVertex, Effect) == 36);
	}

	/// The per pipeline constructors write their values where the shaders read them.
	[Test]
	public static void ThePerPipelineConstructorsWriteWhereTheShadersRead()
	{
		// The box shadow: the SDF operand rides TexCoord and the signed corner radius Coverage.
		let shadow = VGVertex.BoxShadow(.(1.0f, 2.0f), .(-0.5f, 0.25f), .Red, -1.5f);
		Test.Assert(shadow.Position == Float2(1.0f, 2.0f));
		Test.Assert(shadow.TexCoord == Float2(-0.5f, 0.25f));
		Test.Assert(shadow.Color == Color.Red);
		Test.Assert(shadow.Coverage == -1.5f);
		Test.Assert(shadow.Effect == Float2(0.0f, 0.0f));

		// A glyph: full coverage, the edge shift and ramp in Effect.
		let glyph = VGVertex.Glyph(.(3.0f, 4.0f), .(0.1f, 0.2f), .White, .(0.125f, 0.25f));
		Test.Assert(glyph.TexCoord == Float2(0.1f, 0.2f));
		Test.Assert(glyph.Coverage == 1.0f);
		Test.Assert(glyph.Effect == Float2(0.125f, 0.25f));

		// A layer composite: the filter as offsets from none, so a plain composite carries zeros.
		let plain = VGVertex.LayerComposite(.(0.0f, 0.0f), .(1.0f, 1.0f), .White, 1.0f, 1.0f);
		Test.Assert(plain.Effect == Float2(0.0f, 0.0f));
		Test.Assert(plain.Coverage == 1.0f);
		let filtered = VGVertex.LayerComposite(.(0.0f, 0.0f), .(1.0f, 1.0f), .White, 0.25f, 1.5f);
		Test.Assert(filtered.Effect == Float2(0.75f, 0.5f));
	}
}
