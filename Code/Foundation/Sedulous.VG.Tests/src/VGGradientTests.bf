using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Baking gradient ramps, binding them, and the cache that keeps their identities stable.
class VGGradientTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static Path Rect(float x, float y, float w, float h)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x, y);
		builder.LineTo(x + w, y);
		builder.LineTo(x + w, y + h);
		builder.LineTo(x, y + h);
		builder.Close();
		return builder.ToPath();
	}

	private static VGLinearGradientFill Linear(Color from, Color to)
	{
		let fill = new VGLinearGradientFill(.(0, 0), .(100, 0));
		fill.AddStop(0.0f, from);
		fill.AddStop(1.0f, to);
		return fill;
	}

	/// A gradient bakes a ramp and binds it as the active texture, so the shader samples
	/// it per pixel rather than interpolating between corners.
	[Test]
	public static void AGradientBakesAndBindsARamp()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = Linear(.Red, .Blue);
		defer delete fill;

		context.FillPath(path, fill);

		let batch = context.GetBatch();
		Test.Assert(batch.Textures.Count == 2, "the white one and the ramp");

		let ramp = batch.Textures[1];
		Test.Assert(ramp.Width == 256, "one row of two hundred and fifty six steps");
		Test.Assert(ramp.Height == 1);
		// The GPU decodes it to linear on sample, matching the vertex colour path.
		Test.Assert(ramp.ColorSpace == .Srgb);
	}

	/// A solid fill needs no ramp and stays on the white passthrough.
	[Test]
	public static void ASolidFillBakesNothing()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = scope VGSolidFill(.Red);

		context.FillPath(path, fill);

		let batch = context.GetBatch();
		Test.Assert(batch.Textures.Count == 1);
		Test.Assert(batch.Commands[0].TextureIndex == 0);
	}

	/// Identical ramps share ONE image, which is the stable identity the renderer's texture
	/// cache keys on. A per frame pool would hand a reallocated ramp a stale GPU texture.
	[Test]
	public static void IdenticalRampsShareOneImage()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;

		let first = Linear(.Red, .Blue);
		defer delete first;
		let second = Linear(.Red, .Blue);
		defer delete second;

		context.FillPath(path, first);
		context.FillPath(path, second);

		let batch = context.GetBatch();
		Test.Assert(batch.Textures.Count == 2, "two fills, one ramp");
	}

	/// And a different ramp is a different image.
	[Test]
	public static void ADifferentRampIsADifferentImage()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;

		let redBlue = Linear(.Red, .Blue);
		defer delete redBlue;
		let greenBlack = Linear(.Green, .Black);
		defer delete greenBlack;

		context.FillPath(path, redBlue);
		context.FillPath(path, greenBlack);

		Test.Assert(context.GetBatch().Textures.Count == 3);
	}

	/// The identity survives a frame boundary, so the renderer's GPU texture stays valid.
	[Test]
	public static void ARampIdentityIsStableAcrossFrames()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = Linear(.Red, .Blue);
		defer delete fill;

		context.FillPath(path, fill);
		let first = context.GetBatch().Textures[1];

		context.Clear();
		context.FillPath(path, fill);
		let second = context.GetBatch().Textures[1];

		Test.Assert(first == second, "the same image, frame after frame");
	}

	/// After a gradient, a later plain draw recovers rather than being left bound to the
	/// ramp and the gradient pipeline.
	[Test]
	public static void ALaterSolidDrawRecoversFromAGradient()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = Linear(.Red, .Blue);
		defer delete fill;

		context.FillPath(path, fill);
		context.FillRect(.(200, 0, 10, 10), .Green);

		let batch = context.GetBatch();
		let last = batch.Commands[batch.Commands.Count - 1];
		Test.Assert(last.TextureIndex == 0, "back on the white passthrough");
		Test.Assert(last.DrawMode == .Default);
	}

	/// Per pixel gradients are OFF by default, because a host whose renderer lacks those
	/// shaders would have no pipeline for those draw modes at all.
	[Test]
	public static void PerPixelGradientsAreOffByDefault()
	{
		let context = scope VGContext();
		Test.Assert(!context.PerPixelGradients);

		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = scope VGRadialGradientFill(.(50, 50), 50);
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		context.FillPath(path, fill);

		let batch = context.GetBatch();
		Test.Assert(batch.Commands[0].DrawMode == .Default, "the affine approximation");
	}

	/// With them on, a radial gradient takes its own draw mode and the vertices carry
	/// gradient coordinates instead of colours.
	[Test]
	public static void ARadialGradientUpgradesWhenEnabled()
	{
		let context = scope VGContext();
		context.SetPerPixelGradients(true);
		context.SetPixelSnapEnabled(false);

		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = scope VGRadialGradientFill(.(50, 50), 50);
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		context.FillPath(path, fill);

		let batch = context.GetBatch();
		Test.Assert(batch.Commands[0].DrawMode == .GradientRadial);
		for (let vertex in batch.Vertices)
			Test.Assert(vertex.Color == Color.White, "the colour is the shader's job");
	}

	[Test]
	public static void AConicGradientUpgradesWhenEnabled()
	{
		let context = scope VGContext();
		context.SetPerPixelGradients(true);

		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = scope VGConicGradientFill(.(50, 50));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		context.FillPath(path, fill);
		Test.Assert(context.GetBatch().Commands[0].DrawMode == .GradientConic);
	}

	/// A LINEAR gradient stays on the default pipeline whatever the setting: its parameter
	/// is affine, so interpolating it is already exact.
	[Test]
	public static void ALinearGradientNeverNeedsItsOwnPipeline()
	{
		let context = scope VGContext();
		context.SetPerPixelGradients(true);

		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = Linear(.Red, .Blue);
		defer delete fill;

		context.FillPath(path, fill);
		Test.Assert(context.GetBatch().Commands[0].DrawMode == .Default);
	}

	/// The fill's spread rides the command, because it is the ramp sampler's address mode
	/// and two fills sharing one ramp may still spread differently.
	[Test]
	public static void TheFillsSpreadRidesTheCommand()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;

		let fill = Linear(.Red, .Blue);
		defer delete fill;
		fill.Spread = .Reflect;

		context.FillPath(path, fill);
		Test.Assert(context.GetBatch().Commands[0].GradientSpread == .Reflect);
	}

	/// Over budget the whole cache is dropped and the renderer is TOLD which identities
	/// died, so it can free the textures it built from them.
	[Test]
	public static void AnOverBudgetCacheIsAnnouncedThroughTheBatch()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;

		// Each fill is a distinct ramp, which is what an animated gradient colour looks
		// like frame to frame.
		let fills = scope List<VGLinearGradientFill>();
		defer { ClearAndDeleteItems!(fills); }

		for (int i = 0; i <= VGContext.cMaxGradientLutCacheEntries; i++)
		{
			let fill = Linear(.((float)i / 300.0f, 0, 0, 1), .Blue);
			fills.Add(fill);
			context.FillPath(path, fill);
		}

		// The eviction happens on the frame boundary, not mid frame.
		Test.Assert(context.GetBatch().EvictedTextures.IsEmpty);

		context.Clear();
		let batch = context.GetBatch();
		Test.Assert(!batch.EvictedTextures.IsEmpty, "the renderer is told what died");
		Test.Assert(batch.EvictedTextures.Count > VGContext.cMaxGradientLutCacheEntries);
	}

	/// The announced identities are held one more frame, so they are not already dangling
	/// while the renderer's own frame is still in flight.
	[Test]
	public static void EvictedIdentitiesSurviveTheAnnouncingFrame()
	{
		let context = scope VGContext();
		let path = Rect(0, 0, 100, 100);
		defer delete path;

		let fills = scope List<VGLinearGradientFill>();
		defer { ClearAndDeleteItems!(fills); }
		for (int i = 0; i <= VGContext.cMaxGradientLutCacheEntries; i++)
		{
			let fill = Linear(.((float)i / 300.0f, 0, 0, 1), .Blue);
			fills.Add(fill);
			context.FillPath(path, fill);
		}

		context.Clear();
		let announced = context.GetBatch().EvictedTextures[0];

		// Still readable this frame: the renderer has not consumed the list yet.
		Test.Assert(announced.Width == 256);

		// And the NEXT clear is what finally lets them go.
		context.Clear();
		Test.Assert(context.GetBatch().EvictedTextures.IsEmpty);
	}

	/// A gradient through the STENCIL path binds its ramp the same way the tessellated one
	/// does, so a complex shape and a simple one are shaded identically.
	[Test]
	public static void AStencilCoverCarriesTheGradientToo()
	{
		let context = scope VGContext();
		context.SetStencilFills(true);
		context.SetPerPixelGradients(true);

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(100, 0);
		builder.LineTo(100, 100);
		builder.LineTo(0, 100);
		builder.Close();
		builder.MoveTo(25, 25);
		builder.LineTo(25, 75);
		builder.LineTo(75, 75);
		builder.LineTo(75, 25);
		builder.Close();
		let path = builder.ToPath();
		defer delete path;

		let fill = scope VGRadialGradientFill(.(50, 50), 50);
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		context.FillPath(path, fill, .EvenOdd);

		let batch = context.GetBatch();
		var sawGradientCover = false;
		for (let command in batch.Commands)
		{
			if ((command.FillPhase == .StencilCover) && (command.DrawMode == .GradientRadial))
				sawGradientCover = true;
		}
		Test.Assert(sawGradientCover, "the cover quad carries the gradient");
	}

	/// Opacity reaches a gradient's vertices too, which the solid path gets through the
	/// colour it was handed.
	[Test]
	public static void OpacityReachesAGradientsVertices()
	{
		let context = scope VGContext();
		context.SetPixelSnapEnabled(false);
		context.PushOpacity(0.5f);

		let path = Rect(0, 0, 100, 100);
		defer delete path;
		let fill = Linear(.Red, .Blue);
		defer delete fill;

		context.FillPath(path, fill);

		let batch = context.GetBatch();
		var sawFaded = false;
		for (let vertex in batch.Vertices)
		{
			if (Near(vertex.Color.A, 0.5f))
				sawFaded = true;
		}
		Test.Assert(sawFaded);
	}
}
