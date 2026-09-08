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
		Test.Assert(VGVertex.SizeInBytes == 36, "two float2s, a float4 colour, and a coverage");
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
}
