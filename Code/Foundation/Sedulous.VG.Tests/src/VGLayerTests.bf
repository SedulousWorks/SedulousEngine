using System;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Offscreen layers (VGContext.PushLayer): a group drawn into a target of its own and composited
/// once, so it fades as one.
class VGLayerTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static Path Square(float x0, float y0, float x1, float y1)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x0, y0);
		builder.LineTo(x1, y0);
		builder.LineTo(x1, y1);
		builder.LineTo(x0, y1);
		builder.Close();
		return builder.ToPath();
	}

	private static float FirstAlpha(VGBatch batch, VGCommand command)
		=> batch.Vertices[(int)batch.Indices[command.StartIndex]].Color.A;

	/// A layer's draws go into it, and its composite, with the opacity applied once, into what
	/// is under it.
	[Test]
	public static void ALayersDrawsGoIntoItAndItsCompositeIntoWhatIsUnderIt()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		let corner = Square(0, 0, 5, 5);
		defer delete corner;
		let red = Square(10, 10, 30, 30);
		defer delete red;
		let blue = Square(20, 20, 40, 40);
		defer delete blue;

		context.FillPath(corner, .White, .NonZero, false); // before: the target
		context.PushLayer(0.5f);
		context.FillPath(red, .Red, .NonZero, false);
		context.FillPath(blue, .Blue, .NonZero, false);
		context.PopLayer();
		context.FillPath(corner, .White, .NonZero, false); // after: the target

		let batch = context.GetBatch();
		Test.Assert(batch.Layers.Count == 1);
		let layer = batch.Layers[0];
		Test.Assert(layer.Parent == -1);
		Test.Assert(Near(layer.Opacity, 0.5f));
		// The content's bounds, on whole pixels with a pixel of margin.
		Test.Assert(Near(layer.Bounds.X, 9.0f) && Near(layer.Bounds.Width, 32.0f));
		Test.Assert(batch.Commands.Count == 4);
		Test.Assert(batch.Commands[0].Layer == -1);
		Test.Assert(batch.Commands[1].Layer == 0, "red and blue, one command, into the layer");
		Test.Assert(batch.Commands[2].DrawMode == .Layer);
		Test.Assert(batch.Commands[2].Layer == -1);
		Test.Assert(batch.Commands[2].CompositeLayer == 0);
		Test.Assert(Near(FirstAlpha(batch, batch.Commands[2]), 0.5f), "the opacity, applied once, at the composite");
		Test.Assert(batch.Commands[3].Layer == -1);
	}

	/// Inside a layer no clip or opacity applies; around it they apply to its composite.
	[Test]
	public static void InsideALayerNoClipOrOpacityAppliesAroundItTheyApplyToItsComposite()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		context.SetStencilFills(true);
		let clip = Square(0, 0, 50, 50);
		defer delete clip;
		let fill = Square(10, 10, 20, 20);
		defer delete fill;

		context.PushClipPath(clip);
		context.PushOpacity(0.5f);
		context.PushLayer(0.8f);
		context.FillPath(fill, .Red, .NonZero, false);
		context.PopLayer();
		context.PopOpacity();
		context.PopClipPath();

		let batch = context.GetBatch();
		VGCommand? inside = null;
		VGCommand? composite = null;
		for (let command in batch.Commands)
		{
			if (command.Layer == 0)
				inside = command;
			if (command.CompositeLayer == 0)
				composite = command;
		}
		Test.Assert(inside.HasValue && composite.HasValue);
		Test.Assert(inside.Value.ClipMode == .None);
		Test.Assert(Near(FirstAlpha(batch, inside.Value), 1.0f));
		Test.Assert(composite.Value.ClipMode == .Stencil);
		Test.Assert(Near(FirstAlpha(batch, composite.Value), 0.4f), "0.8 of the layer, times the 0.5 around it");
	}

	/// A layer inside a layer composites into it, and an empty layer has no bounds and no
	/// composite.
	[Test]
	public static void ALayerInsideALayerCompositesIntoIt()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		let red = Square(0, 0, 10, 10);
		defer delete red;
		let blue = Square(40, 40, 50, 50);
		defer delete blue;

		context.PushLayer(0.5f);
		context.FillPath(red, .Red, .NonZero, false);
		context.PushLayer(0.5f);
		context.FillPath(blue, .Blue, .NonZero, false);
		context.PopLayer();
		context.PopLayer();
		context.PushLayer(1.0f);
		context.PopLayer(); // empty: no bounds, no composite

		let batch = context.GetBatch();
		Test.Assert(batch.Layers.Count == 3);
		Test.Assert(batch.Layers[1].Parent == 0);
		Test.Assert(Near(batch.Layers[0].Bounds.Width, 53.0f), "its fill (0..10) and the inner composite (39..51), padded");
		Test.Assert(Near(batch.Layers[2].Bounds.Width, 0.0f));
		var composites = 0;
		for (let command in batch.Commands)
		{
			if (command.CompositeLayer == 1)
			{
				Test.Assert(command.Layer == 0);
				composites++;
			}
			if (command.CompositeLayer == 0)
			{
				Test.Assert(command.Layer == -1);
				composites++;
			}
			Test.Assert(command.CompositeLayer != 2);
		}
		Test.Assert(composites == 2);
	}

	/// Without layers (the host never said its renderer draws them), a layer is an opacity push.
	[Test]
	public static void WithoutLayersALayerIsAnOpacityPush()
	{
		let context = scope VGContext();
		let first = Square(10, 10, 30, 30);
		defer delete first;
		let second = Square(40, 40, 50, 50);
		defer delete second;

		context.PushOpacity(0.5f);
		context.PushLayer(0.5f);
		context.FillPath(first, .Red, .NonZero, false);
		context.PopLayer();
		context.FillPath(second, .Red, .NonZero, false);
		context.PopOpacity();

		let batch = context.GetBatch();
		Test.Assert(batch.Layers.IsEmpty);
		Test.Assert(batch.Commands.Count == 1, "no layer, no composite: one run of fills");
		Test.Assert(batch.Commands[0].Layer == -1);
		Test.Assert(Near(batch.Vertices[(int)batch.Indices[0]].Color.A, 0.25f));
		Test.Assert(Near(batch.Vertices.Back.Color.A, 0.5f), "the layer's opacity popped");
	}

	/// A blurred layer carries its sigma, clamped to the widest, and three sigmas of margin past
	/// its content's bounds.
	[Test]
	public static void ABlurredLayerCarriesItsSigmaAndThreeSigmasOfMargin()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		let fill = Square(10, 10, 30, 30);
		defer delete fill;
		context.PushLayer(1.0f, .Normal, 4.0f);
		context.FillPath(fill, .Red, .NonZero, false);
		context.PopLayer();
		context.PushLayer(1.0f, .Normal, 500.0f); // past the widest
		context.FillPath(fill, .Red, .NonZero, false);
		context.PopLayer();

		let batch = context.GetBatch();
		Test.Assert(batch.Layers.Count == 2);
		Test.Assert(Near(batch.Layers[0].Blur, 4.0f));
		Test.Assert(Near(batch.Layers[0].Bounds.X, 9.0f - 12.0f), "the pixel margin, then three sigmas");
		Test.Assert(Near(batch.Layers[0].Bounds.Width, 22.0f + 24.0f));
		Test.Assert(Near(batch.Layers[1].Blur, VGContext.MaxLayerBlur));
	}

	/// A backdrop blur moves what was drawn into a layer, the layers composited before it with it,
	/// composites that layer unclipped as drawn, and shows its blurred copy in the shape; what is
	/// drawn after it stays in the target.
	[Test]
	public static void ABackdropBlurMovesWhatWasDrawnIntoALayerAndShowsItsBlurredCopy()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		let red = Square(0, 0, 40, 40);
		defer delete red;
		let green = Square(50, 0, 60, 10);
		defer delete green;
		let blue = Square(0, 50, 10, 60);
		defer delete blue;

		context.FillPath(red, .Red, .NonZero, false);
		context.PushLayer(0.5f); // drawn before the backdrop: becomes a child of the moved layer
		context.FillPath(green, .Green, .NonZero, false);
		context.PopLayer();
		context.DrawBackdropBlur(.(10, 10, 20, 20), .(4.0f), 3.0f);
		context.FillPath(blue, .Blue, .NonZero, false); // after: the target

		let batch = context.GetBatch();
		Test.Assert(batch.Layers.Count == 2);
		let behind = batch.Layers[1];
		Test.Assert(behind.Parent == -1);
		Test.Assert(Near(behind.BackdropBlur, 3.0f));
		Test.Assert(Near(behind.Opacity, 1.0f));
		Test.Assert(batch.Layers[0].Parent == 1, "the earlier layer now composites into the moved one");
		Test.Assert(batch.Commands[0].Layer == 1, "the red fill moved");
		var composites = 0;
		var backdrops = 0;
		for (let command in batch.Commands)
		{
			if ((command.CompositeLayer == 1) && !command.Backdrop)
			{
				Test.Assert(command.Layer == -1);
				Test.Assert(command.ClipMode == .None);
				composites++;
			}
			if (command.Backdrop)
			{
				Test.Assert(command.DrawMode == .Layer);
				Test.Assert(command.CompositeLayer == 1);
				Test.Assert(command.Layer == -1);
				backdrops++;
			}
		}
		Test.Assert(composites == 1);
		Test.Assert(backdrops >= 1);
		Test.Assert(batch.Commands.Back.Layer == -1, "the blue fill after it stays in the target");
		Test.Assert(batch.Commands.Back.DrawMode != .Layer);
	}

	/// No backdrop blur without layers, or inside a clip path.
	[Test]
	public static void NoBackdropBlurWithoutLayersOrInsideAClipPath()
	{
		let red = Square(0, 0, 40, 40);
		defer delete red;
		{
			let context = scope VGContext();
			context.FillPath(red, .Red, .NonZero, false);
			context.DrawBackdropBlur(.(10, 10, 20, 20), .(4.0f), 3.0f);
			Test.Assert(context.GetBatch().Layers.IsEmpty);
			Test.Assert(context.GetBatch().Commands.Count == 1);
		}
		{
			let context = scope VGContext();
			context.SetLayers(true);
			context.SetStencilFills(true);
			let clip = Square(0, 0, 30, 30);
			defer delete clip;
			context.FillPath(red, .Red, .NonZero, false);
			context.PushClipPath(clip);
			context.DrawBackdropBlur(.(10, 10, 20, 20), .(4.0f), 3.0f);
			context.PopClipPath();
			Test.Assert(context.GetBatch().Layers.IsEmpty);
		}
	}

	/// Past MaxLayers in a batch a layer is an opacity push, so a long list of faded rows still
	/// draws, each row fading on its own.
	[Test]
	public static void PastMaxLayersALayerIsAnOpacityPush()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		let fill = Square(0, 0, 10, 10);
		defer delete fill;
		for (int i < VGContext.MaxLayers + 2)
		{
			context.PushLayer(0.5f);
			context.FillPath(fill, .Red, .NonZero, false);
			context.PopLayer();
		}

		let batch = context.GetBatch();
		Test.Assert(batch.Layers.Count == VGContext.MaxLayers);
		Test.Assert(batch.Commands.Back.Layer == -1);
		Test.Assert(Near(batch.Vertices.Back.Color.A, 0.5f), "faded on its own");
	}

	/// A layer left open when the context is cleared is freed with it, and the next frame starts
	/// on the target again.
	[Test]
	public static void ClearingWithALayerOpenStartsAgainOnTheTarget()
	{
		let context = scope VGContext();
		context.SetLayers(true);
		context.PushLayer(0.5f);
		context.Clear();

		let fill = Square(0, 0, 10, 10);
		defer delete fill;
		context.FillPath(fill, .Red, .NonZero, false);
		let batch = context.GetBatch();
		Test.Assert(batch.Layers.IsEmpty);
		Test.Assert(batch.Commands[0].Layer == -1);
	}
}
