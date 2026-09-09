using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// Accumulating the debug drawing.
class DebugDrawTests
{
	[Test]
	public static void AFreshAccumulatorHasNothingToDraw()
	{
		let draw = scope DebugDraw();
		Test.Assert(!draw.HasAnyDraws);
		Test.Assert(draw.LineVertices.Length == 0);
	}

	[Test]
	public static void ALineIsTwoVerticesOfOneColour()
	{
		let draw = scope DebugDraw();
		draw.DrawLine(.(0, 0, 0), .(1, 2, 3), .(1, 0, 0, 1));

		Test.Assert(draw.LineVertices.Length == 2);
		Test.Assert(draw.LineVertices[0].Position == Float3(0, 0, 0));
		Test.Assert(draw.LineVertices[1].Position == Float3(1, 2, 3));
		Test.Assert(draw.LineVertices[0].Color == draw.LineVertices[1].Color);
		Test.Assert(draw.HasAnyDraws);
	}

	/// The overlay work goes into ITS OWN list, since the two are drawn by different pipelines.
	[Test]
	public static void TheOverlayBucketIsSeparate()
	{
		let draw = scope DebugDraw();
		draw.DrawLine(.(0, 0, 0), .(1, 0, 0), .(1, 1, 1, 1));
		draw.DrawLineOverlay(.(0, 0, 0), .(0, 1, 0), .(1, 1, 1, 1));
		draw.DrawTriangle(.(0, 0, 0), .(1, 0, 0), .(0, 1, 0), .(1, 1, 1, 1), true);

		Test.Assert(draw.LineVertices.Length == 2);
		Test.Assert(draw.OverlayLineVertices.Length == 2);
		Test.Assert(draw.TriangleVertices.Length == 0);
		Test.Assert(draw.OverlayTriangleVertices.Length == 3);
	}

	/// RED in the LOW byte, which is the opposite of the colour's own packing: a normalised
	/// byte vertex attribute reads the low byte as the first component.
	[Test]
	public static void TheColourPacksWithRedLowest()
	{
		let packed = DebugDraw.PackColor(.(1.0f, 0.0f, 0.0f, 1.0f));
		Test.Assert((packed & 0xFF) == 255);
		Test.Assert(((packed >> 8) & 0xFF) == 0);
		Test.Assert(((packed >> 16) & 0xFF) == 0);
		Test.Assert(((packed >> 24) & 0xFF) == 255);
	}

	[Test]
	public static void TheColourClampsRatherThanWrapping()
	{
		let packed = DebugDraw.PackColor(.(2.0f, -1.0f, 0.0f, 1.0f));
		Test.Assert((packed & 0xFF) == 255);
		Test.Assert(((packed >> 8) & 0xFF) == 0);
	}

	[Test]
	public static void AQuadIsTwoTriangles()
	{
		let draw = scope DebugDraw();
		draw.DrawQuad(.(0, 0, 0), .(1, 0, 0), .(1, 1, 0), .(0, 1, 0), .(1, 1, 1, 1));
		Test.Assert(draw.TriangleVertices.Length == 6);
	}

	[Test]
	public static void AWireBoxIsTwelveEdges()
	{
		let draw = scope DebugDraw();
		draw.DrawWireBox(.(-1, -1, -1), .(1, 1, 1), .(1, 1, 1, 1));
		Test.Assert(draw.LineVertices.Length == 24);
	}

	[Test]
	public static void AFilledBoxIsSixQuads()
	{
		let draw = scope DebugDraw();
		draw.DrawFilledBox(.(-1, -1, -1), .(1, 1, 1), .(1, 1, 1, 1));
		Test.Assert(draw.TriangleVertices.Length == 36);
	}

	/// The centre and half extent form is the same box as the corner form.
	[Test]
	public static void TheCentreFormMatchesTheCornerForm()
	{
		let corners = scope DebugDraw();
		corners.DrawWireBox(.(1, 1, 1), .(3, 3, 3), .(1, 1, 1, 1));

		let centred = scope DebugDraw();
		centred.DrawWireBoxCenter(.(2, 2, 2), .(1, 1, 1), .(1, 1, 1, 1));

		Test.Assert(corners.LineVertices.Length == centred.LineVertices.Length);
		for (int i < corners.LineVertices.Length)
			Test.Assert(corners.LineVertices[i].Position == centred.LineVertices[i].Position);
	}

	[Test]
	public static void ACircleIsOneSegmentPerStep()
	{
		let draw = scope DebugDraw();
		draw.DrawCircle(.(0, 0, 0), .(1, 0, 0), .(0, 1, 0), 1.0f, .(1, 1, 1, 1), 8);
		Test.Assert(draw.LineVertices.Length == 16);
	}

	/// The circle closes: the last segment ends where the first began.
	[Test]
	public static void ACircleCloses()
	{
		let draw = scope DebugDraw();
		draw.DrawCircle(.(0, 0, 0), .(1, 0, 0), .(0, 1, 0), 2.0f, .(1, 1, 1, 1), 12);

		let first = draw.LineVertices[0].Position;
		let last = draw.LineVertices[draw.LineVertices.Length - 1].Position;
		Test.Assert(Length(last - first) < 0.001f);
	}

	/// The rows are the basis, this being the row vector convention, so the axes come off the
	/// rows and the origin off the last one.
	[Test]
	public static void TheAxesComeOffTheRows()
	{
		var transform = Float4x4.Identity();
		transform.M[3][0] = 5.0f;

		let draw = scope DebugDraw();
		draw.DrawAxis(transform, 2.0f);

		Test.Assert(draw.LineVertices.Length == 6);
		Test.Assert(draw.LineVertices[0].Position == Float3(5, 0, 0));
		Test.Assert(draw.LineVertices[1].Position == Float3(7, 0, 0));
		Test.Assert(draw.LineVertices[3].Position == Float3(5, 2, 0));
		Test.Assert(draw.LineVertices[5].Position == Float3(5, 0, 2));
	}

	[Test]
	public static void TextGoesIntoTheSharedStore()
	{
		let draw = scope DebugDraw();
		draw.DrawScreenText(10, 20, "AB", .(1, 1, 1, 1));
		draw.DrawScreenText(10, 40, "C", .(1, 1, 1, 1));

		Test.Assert(draw.Commands2D.Length == 2);
		Test.Assert(draw.TextChars.Length == 3);
		Test.Assert(draw.Commands2D[0].TextStart == 0);
		Test.Assert(draw.Commands2D[0].TextLength == 2);
		Test.Assert(draw.Commands2D[1].TextStart == 2);
		Test.Assert(draw.Commands2D[1].TextLength == 1);
		Test.Assert(draw.TextChars[2] == (uint8)'C');
	}

	[Test]
	public static void EmptyTextRecordsNothing()
	{
		let draw = scope DebugDraw();
		draw.DrawScreenText(0, 0, "", .(1, 1, 1, 1));
		draw.DrawText3D(.(0, 0, 0), "", .(1, 1, 1, 1));

		Test.Assert(draw.Commands2D.Length == 0);
		Test.Assert(draw.TextCommands3D.Length == 0);
		Test.Assert(!draw.HasAnyDraws);
	}

	/// A NEGATIVE horizontal position is what tells the screen pass to right align, so a margin
	/// of nought must still come out negative rather than reading as a left aligned nought.
	[Test]
	public static void RightAlignedTextIsFlaggedByASignEvenAtZero()
	{
		let draw = scope DebugDraw();
		draw.DrawScreenTextRight(0.0f, 5.0f, "X", .(1, 1, 1, 1));
		Test.Assert(draw.Commands2D[0].Position.X < 0.0f);
	}

	[Test]
	public static void ARectangleCarriesNoText()
	{
		let draw = scope DebugDraw();
		draw.DrawScreenRect(1, 2, 30, 40, .(1, 1, 1, 1));

		Test.Assert(draw.Commands2D.Length == 1);
		Test.Assert(draw.Commands2D[0].Kind == .Rectangle);
		Test.Assert(draw.Commands2D[0].Size == Float2(30, 40));
		Test.Assert(draw.Commands2D[0].TextLength == 0);
		Test.Assert(draw.TextChars.Length == 0);
	}

	[Test]
	public static void ClearingDropsTheTextStoreToo()
	{
		let draw = scope DebugDraw();
		draw.DrawLine(.(0, 0, 0), .(1, 1, 1), .(1, 1, 1, 1));
		draw.DrawLineOverlay(.(0, 0, 0), .(1, 1, 1), .(1, 1, 1, 1));
		draw.DrawScreenText(0, 0, "hello", .(1, 1, 1, 1));
		draw.DrawText3D(.(0, 0, 0), "world", .(1, 1, 1, 1));

		draw.Clear();

		Test.Assert(!draw.HasAnyDraws);
		Test.Assert(draw.TextChars.Length == 0);
		Test.Assert(draw.TextCommands3D.Length == 0);
		Test.Assert(draw.OverlayLineVertices.Length == 0);
	}

	/// The text store is shared between the two kinds of command, so their spans must not
	/// overlap.
	[Test]
	public static void TheTwoKindsOfTextShareTheStoreWithoutOverlapping()
	{
		let draw = scope DebugDraw();
		draw.DrawScreenText(0, 0, "ab", .(1, 1, 1, 1));
		draw.DrawText3D(.(0, 0, 0), "cde", .(1, 1, 1, 1));

		Test.Assert(draw.TextChars.Length == 5);
		Test.Assert(draw.Commands2D[0].TextStart == 0);
		Test.Assert(draw.TextCommands3D[0].TextStart == 2);
		Test.Assert(draw.TextCommands3D[0].TextLength == 3);
	}

	/// The divide by w is the point: an inverse view projection is not affine, and Core's own
	/// transform would leave the corners at the wrong place entirely.
	[Test]
	public static void TheFrustumProjectionDividesByW()
	{
		var m = Float4x4.Identity();
		m.M[0][3] = 0.0f;
		m.M[3][3] = 2.0f;

		let projected = DebugDraw.ProjectPoint(m, .(4, 6, 8));
		Test.Assert(NearlyEqual(projected, Float3(2, 3, 4)));
	}

	[Test]
	public static void ADegenerateWWouldNotDivide()
	{
		var m = Float4x4.Identity();
		m.M[3][3] = 0.0f;

		let projected = DebugDraw.ProjectPoint(m, .(1, 2, 3));
		Test.Assert(NearlyEqual(projected, Float3(1, 2, 3)));
	}

	[Test]
	public static void AFrustumIsTwelveEdges()
	{
		let draw = scope DebugDraw();
		draw.DrawFrustum(Float4x4.Identity(), .(1, 1, 1, 1));
		Test.Assert(draw.LineVertices.Length == 24);
	}

	[Test]
	public static void AGridSpansItsSizeAboutTheCentre()
	{
		let draw = scope DebugDraw();
		draw.DrawGrid(.(0, 0, 0), 4.0f, 2, .(1, 1, 1, 1));

		// Three lines each way, of two vertices.
		Test.Assert(draw.LineVertices.Length == 12);

		var minX = 1000.0f;
		var maxX = -1000.0f;
		for (let vertex in draw.LineVertices)
		{
			minX = Min(minX, vertex.Position.X);
			maxX = Max(maxX, vertex.Position.X);
		}
		Test.Assert(NearlyEqual(minX, -2.0f));
		Test.Assert(NearlyEqual(maxX, 2.0f));
	}

	[Test]
	public static void ARayIsALineFromItsOrigin()
	{
		let draw = scope DebugDraw();
		draw.DrawRay(.(1, 1, 1), .(0, 2, 0), .(1, 1, 1, 1));

		Test.Assert(draw.LineVertices[0].Position == Float3(1, 1, 1));
		Test.Assert(draw.LineVertices[1].Position == Float3(1, 3, 1));
	}
}
