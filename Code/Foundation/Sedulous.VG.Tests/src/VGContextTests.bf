namespace Sedulous.VG.Tests;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

class VGContextTests
{
	[Test]
	public static void FillRect_ProducesVerticesAndIndices()
	{
		let ctx = scope VGContext();
		ctx.FillRect(.(10, 10, 100, 50), Color.Red);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
		Test.Assert(batch.IndexCount > 0);
		Test.Assert(batch.CommandCount > 0);
	}

	[Test]
	public static void StrokeRect_ProducesOutput()
	{
		let ctx = scope VGContext();
		ctx.StrokeRect(.(10, 10, 100, 50), Color.Blue, 2.0f);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
		Test.Assert(batch.IndexCount > 0);
	}

	[Test]
	public static void StateStack_RestoresTransform()
	{
		let ctx = scope VGContext();
		let identity = ctx.GetTransform();

		ctx.PushState();
		ctx.Translate(100, 200);

		let translated = ctx.GetTransform();
		Test.Assert(translated != identity);

		ctx.PopState();
		let restored = ctx.GetTransform();
		Test.Assert(restored == identity);
	}

	[Test]
	public static void ClipRect_AffectsCommands()
	{
		let ctx = scope VGContext();

		ctx.FillRect(.(0, 0, 10, 10), Color.Red);
		ctx.PushClipRect(.(0, 0, 50, 50));
		ctx.FillRect(.(5, 5, 10, 10), Color.Blue);
		ctx.PopClip();

		let batch = ctx.GetBatch();
		// Should have at least 2 commands (before and after clip change)
		Test.Assert(batch.CommandCount >= 2);
	}

	[Test]
	public static void Opacity_AppliedToVertexColor()
	{
		let ctx = scope VGContext();
		ctx.PushOpacity(0.5f);
		ctx.FillRect(.(0, 0, 10, 10), Color.White);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);

		// Check that vertex alpha is approximately half
		for (int i = 0; i < batch.VertexCount; i++)
		{
			let v = batch.Vertices[i];
			Test.Assert(v.Color.A < 200); // Should be ~127
		}
	}

	[Test]
	public static void FillCircle_ProducesOutput()
	{
		let ctx = scope VGContext();
		ctx.FillCircle(.(50, 50), 25, Color.Green);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 8);
		Test.Assert(batch.IndexCount > 0);
	}

	[Test]
	public static void RoundedRect_PerCornerRadii()
	{
		let ctx = scope VGContext();
		ctx.FillRoundedRect(.(0, 0, 100, 100), .(10, 20, 30, 40), Color.White);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 4); // More than a simple rect
		Test.Assert(batch.IndexCount > 6);
	}

	[Test]
	public static void Clear_ResetsEverything()
	{
		let ctx = scope VGContext();
		ctx.FillRect(.(0, 0, 10, 10), Color.Red);

		let batch1 = ctx.GetBatch();
		Test.Assert(batch1.VertexCount > 0);

		ctx.Clear();
		let batch2 = ctx.GetBatch();
		Test.Assert(batch2.VertexCount == 0);
	}

	[Test]
	public static void FillStar_ProducesOutput()
	{
		let ctx = scope VGContext();
		ctx.FillStar(.(50, 50), 30, 15, 5, Color.Yellow);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}
}
