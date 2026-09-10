using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The box shadow primitive: four quadrant quads carrying the rounded box distance operand
/// in sigma units, which is what lets the shader finish the distance per pixel.
class VGBoxShadowTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// The first command drawn in a mode, or false when nothing was.
	private static bool FindCommandWithMode(VGBatch batch, VGDrawMode mode, out VGCommand found)
	{
		for (let command in batch.Commands)
		{
			if (command.DrawMode == mode)
			{
				found = command;
				return true;
			}
		}
		found = .();
		return false;
	}

	[Test]
	public static void FillBoxShadowEmitsFourQuadrantQuadsOverTheBlurredExtent()
	{
		let context = scope VGContext();
		// A blur of twelve is a sigma of six, so the shadow reaches eighteen past the box on
		// every side.
		context.FillBoxShadow(.(10, 20, 100, 50), CornerRadii(8.0f), 12.0f, .(0, 0, 0, 0.5f));
		let batch = context.GetBatch();

		Test.Assert(FindCommandWithMode(batch, .BoxShadow, let command));
		Test.Assert(command.IndexCount == 24, "four quads");
		Test.Assert(command.TextureIndex == 0, "no texture: the solid slot");

		// The sixteen vertices span the box grown by three sigma.
		float minX = float.MaxValue;
		float minY = float.MaxValue;
		float maxX = float.MinValue;
		float maxY = float.MinValue;
		int shadowVertices = 0;
		for (let vertex in batch.Vertices)
		{
			if ((vertex.Color.A <= 0.49f) || (vertex.Color.A >= 0.51f))
				continue;

			shadowVertices++;
			minX = Min(minX, vertex.Position.X);
			maxX = Max(maxX, vertex.Position.X);
			minY = Min(minY, vertex.Position.Y);
			maxY = Max(maxY, vertex.Position.Y);
			// Every vertex carries the corner radius in sigma units, positive when outset.
			Test.Assert(Near(vertex.Coverage, 8.0f / 6.0f));
		}

		Test.Assert(shadowVertices == 16);
		Test.Assert(Near(minX, 10.0f - 18.0f));
		Test.Assert(Near(maxX, 110.0f + 18.0f));
		Test.Assert(Near(minY, 20.0f - 18.0f));
		Test.Assert(Near(maxY, 70.0f + 18.0f));

		// The centre vertex of each quadrant sits deep inside, at q = -(half - r) / sigma.
		int centres = 0;
		for (let vertex in batch.Vertices)
		{
			if (!Near(vertex.Position.X, 60.0f) || !Near(vertex.Position.Y, 45.0f))
				continue;

			centres++;
			Test.Assert(Near(vertex.TexCoord.X, -(50.0f - 8.0f) / 6.0f));
			Test.Assert(Near(vertex.TexCoord.Y, -(25.0f - 8.0f) / 6.0f));
		}
		Test.Assert(centres == 4);
	}

	/// The mode is RESTORED, so an ordinary fill after a shadow is not shaded as one.
	[Test]
	public static void AFillAfterAShadowIsBackInTheDefaultMode()
	{
		let context = scope VGContext();
		context.FillBoxShadow(.(10, 20, 100, 50), CornerRadii(8.0f), 12.0f, .(0, 0, 0, 0.5f));
		context.FillRect(.(0, 0, 5, 5), .Red);

		Test.Assert(FindCommandWithMode(context.GetBatch(), .Default, ?));
	}

	/// No blur is a hard edge, which the ordinary rounded rect path already draws crisply.
	[Test]
	public static void AZeroBlurOutsetShadowIsAPlainRoundedRect()
	{
		let context = scope VGContext();
		context.FillBoxShadow(.(10, 10, 40, 40), CornerRadii(4.0f), 0.0f, .Black);

		let batch = context.GetBatch();
		Test.Assert(!FindCommandWithMode(batch, .BoxShadow, ?));
		Test.Assert(FindCommandWithMode(batch, .Default, ?), "the rounded rect");
	}

	[Test]
	public static void AnInsetShadowStaysInsideTheBoxAndFlagsItselfNegative()
	{
		let context = scope VGContext();
		context.FillBoxShadow(.(10, 10, 40, 40), CornerRadii(4.0f), 8.0f, .Black, true);

		let batch = context.GetBatch();
		Test.Assert(FindCommandWithMode(batch, .BoxShadow, ?));
		for (let vertex in batch.Vertices)
		{
			Test.Assert(vertex.Position.X >= 10.0f - 0.001f);
			Test.Assert(vertex.Position.X <= 50.0f + 0.001f);
			Test.Assert(vertex.Coverage < 0.0f, "the inset flag");
		}
	}

	/// A hard inset shadow has nowhere to fade, so it is nothing at all.
	[Test]
	public static void AZeroBlurInsetShadowDrawsNothing()
	{
		let context = scope VGContext();
		context.FillBoxShadow(.(10, 10, 40, 40), CornerRadii(4.0f), 0.0f, .Black, true);

		Test.Assert(context.GetBatch().Vertices.IsEmpty);
	}
}
