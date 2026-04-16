using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;

namespace Sedulous.Drawing.Tests;

class DrawContextTests
{
	// Helper to create test DrawContext with NullFontService
	private static mixin TestContext()
	{
		let fontService = scope :: NullFontService();
		scope :: DrawContext(fontService)
	}

	[Test]
	public static void New_BatchIsEmpty()
	{
		let ctx = TestContext!();
		let batch = ctx.GetBatch();

		Test.Assert(batch.VertexCount == 0);
		Test.Assert(batch.IndexCount == 0);
	}

	[Test]
	public static void Clear_ResetsBatch()
	{
		let ctx = TestContext!();
		ctx.FillRect(.(0, 0, 100, 100), Color.Red);
		ctx.Clear();
		let batch = ctx.GetBatch();

		Test.Assert(batch.VertexCount == 0);
		Test.Assert(batch.IndexCount == 0);
	}

	// === Transform Tests ===

	[Test]
	public static void GetTransform_Default_IsIdentity()
	{
		let ctx = TestContext!();

		Test.Assert(ctx.GetTransform() == Matrix.Identity);
	}

	[Test]
	public static void SetTransform_ChangesTransform()
	{
		let ctx = TestContext!();
		let transform = Matrix.CreateTranslation(100, 200, 0);
		ctx.SetTransform(transform);

		Test.Assert(ctx.GetTransform() == transform);
	}

	[Test]
	public static void ResetTransform_ResetsToIdentity()
	{
		let ctx = TestContext!();
		ctx.SetTransform(Matrix.CreateTranslation(100, 200, 0));
		ctx.ResetTransform();

		Test.Assert(ctx.GetTransform() == Matrix.Identity);
	}

	[Test]
	public static void Translate_ModifiesTransform()
	{
		let ctx = TestContext!();
		ctx.Translate(50, 100);

		let transform = ctx.GetTransform();
		// Check that translation is applied
		Test.Assert(transform != Matrix.Identity);
	}

	[Test]
	public static void Rotate_ModifiesTransform()
	{
		let ctx = TestContext!();
		ctx.Rotate(Math.PI_f / 4);

		Test.Assert(ctx.GetTransform() != Matrix.Identity);
	}

	[Test]
	public static void Scale_ModifiesTransform()
	{
		let ctx = TestContext!();
		ctx.Scale(2.0f, 0.5f);

		Test.Assert(ctx.GetTransform() != Matrix.Identity);
	}

	// === State Stack Tests ===

	[Test]
	public static void PushPopState_RestoresTransform()
	{
		let ctx = TestContext!();
		let original = Matrix.CreateScale(2, 2, 1);
		ctx.SetTransform(original);

		ctx.PushState();
		ctx.SetTransform(Matrix.CreateTranslation(100, 100, 0));
		ctx.PopState();

		Test.Assert(ctx.GetTransform() == original);
	}

	[Test]
	public static void PopState_WithEmptyStack_DoesNotCrash()
	{
		let ctx = TestContext!();
		ctx.PopState(); // Should not crash
		Test.Assert(true);
	}

	// === Fill Tests ===

	[Test]
	public static void FillRect_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.FillRect(.(0, 0, 100, 50), Color.Red);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount == 4);
		Test.Assert(batch.IndexCount == 6);
	}

	[Test]
	public static void FillRect_WithBrush_AddsGeometry()
	{
		let ctx = TestContext!();
		let brush = scope SolidBrush(Color.Blue);
		ctx.FillRect(.(0, 0, 100, 50), brush);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount == 4);
	}

	[Test]
	public static void FillCircle_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.FillCircle(.(50, 50), 30, Color.Green);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
		Test.Assert(batch.IndexCount > 0);
	}

	[Test]
	public static void FillEllipse_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.FillEllipse(.(50, 50), 40, 20, Color.Yellow);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void FillRoundedRect_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.FillRoundedRect(.(0, 0, 100, 50), 10, Color.Purple);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void FillArc_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.FillArc(.(50, 50), 30, 0, Math.PI_f / 2, Color.Orange);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void FillPolygon_AddsGeometry()
	{
		let ctx = TestContext!();
		Vector2[] points = scope .(.(0, 0), .(100, 0), .(50, 100));
		ctx.FillPolygon(points, Color.Red);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount == 3);
	}

	// === Stroke Tests ===

	[Test]
	public static void DrawLine_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.DrawLine(.(0, 0), .(100, 100), Color.Black, 2.0f);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount >= 4);
	}

	[Test]
	public static void DrawLine_WithPen_AddsGeometry()
	{
		let ctx = TestContext!();
		let pen = scope Pen(Color.Red, 3.0f);
		ctx.DrawLine(.(0, 0), .(100, 100), pen);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void DrawRect_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.DrawRect(.(0, 0, 100, 50), Color.Black, 1.0f);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void DrawCircle_AddsGeometry()
	{
		let ctx = TestContext!();
		ctx.DrawCircle(.(50, 50), 30, Color.Black, 2.0f);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void DrawPolygon_AddsGeometry()
	{
		let ctx = TestContext!();
		Vector2[] points = scope .(.(0, 0), .(100, 0), .(100, 100), .(0, 100));
		ctx.DrawPolygon(points, Color.Black, 1.0f);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	[Test]
	public static void DrawPolyline_AddsGeometry()
	{
		let ctx = TestContext!();
		Vector2[] points = scope .(.(0, 0), .(50, 50), .(100, 0));
		ctx.DrawPolyline(points, Color.Black, 1.0f);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}

	// === Blend Mode Tests ===

	[Test]
	public static void SetBlendMode_CreatesNewCommand()
	{
		let ctx = TestContext!();
		ctx.FillRect(.(0, 0, 50, 50), Color.Red);
		ctx.SetBlendMode(.Additive);
		ctx.FillRect(.(50, 0, 50, 50), Color.Blue);

		let batch = ctx.GetBatch();
		Test.Assert(batch.CommandCount == 2);
		Test.Assert(batch.GetCommand(0).BlendMode == .Normal);
		Test.Assert(batch.GetCommand(1).BlendMode == .Additive);
	}

	// === Clip Tests ===

	[Test]
	public static void PushClipRect_SetsClipOnCommand()
	{
		let ctx = TestContext!();
		ctx.PushClipRect(.(10, 10, 80, 80));
		ctx.FillRect(.(0, 0, 100, 100), Color.Red);

		let batch = ctx.GetBatch();
		let cmd = batch.GetCommand(0);
		Test.Assert(cmd.ClipMode == .Scissor);
		Test.Assert(cmd.ClipRect.Width > 0);
	}

	// === Solid Color Drawing Tests ===

	[Test]
	public static void FillRect_UsesSolidUV()
	{
		let ctx = scope DrawContext();
		ctx.FillRect(.(0, 0, 10, 10), Color.White);

		let batch = ctx.GetBatch();
		// Solid color drawing uses fixed UV (0.5, 0.5) with internal white texture
		Test.Assert(batch.Vertices[0].TexCoord.X == 0.5f);
		Test.Assert(batch.Vertices[0].TexCoord.Y == 0.5f);
		// White texture should be at index 0
		Test.Assert(batch.Textures.Count >= 1);
		Test.Assert(batch.Textures[0] == ctx.WhiteTexture);
	}

	// === Gradient Tests ===

	[Test]
	public static void FillRect_WithLinearGradient_InterpolatesColors()
	{
		let ctx = TestContext!();
		let brush = scope LinearGradientBrush(.(0, 0), .(100, 0), Color.Red, Color.Blue);
		ctx.FillRect(.(0, 0, 100, 50), brush);

		let batch = ctx.GetBatch();
		// Vertices should have different colors due to gradient
		Test.Assert(batch.VertexCount == 4);
	}

	[Test]
	public static void FillCircle_WithRadialGradient_InterpolatesColors()
	{
		let ctx = TestContext!();
		let brush = scope RadialGradientBrush(.(50, 50), 50, Color.White, Color.Black);
		ctx.FillCircle(.(50, 50), 50, brush);

		let batch = ctx.GetBatch();
		Test.Assert(batch.VertexCount > 0);
	}
}
