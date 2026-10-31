using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.UI;

/// Stacks drawables, each with its own inset, drawn in the order they were added.
class LayerDrawable : Drawable
{
	private struct Layer
	{
		public Drawable Content;
		public Thickness Inset;
	}

	private List<Layer> mLayers = new .() ~ ReleaseLayers(_);

	public this() {}

	private static void ReleaseLayers(List<Layer> layers)
	{
		for (let layer in layers)
		{
			if (layer.Content != null)
				layer.Content.ReleaseRef();
		}
		delete layers;
	}

	/// CONSUMES the caller's reference on `drawable`.
	public void AddLayer(Drawable drawable, Thickness inset = .())
	{
		mLayers.Add(.() { Content = drawable, Inset = inset });
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		for (let layer in mLayers)
		{
			if (layer.Content != null)
				layer.Content.Draw(ctx, LayerBounds(bounds, layer.Inset));
		}
	}

	protected override void DrawState(UIDrawContext ctx, Rectangle bounds, ControlState state)
	{
		for (let layer in mLayers)
		{
			if (layer.Content != null)
				layer.Content.Draw(ctx, LayerBounds(bounds, layer.Inset), state);
		}
	}

	private static Rectangle LayerBounds(Rectangle bounds, Thickness inset) =>
		.(bounds.X + inset.Left, bounds.Y + inset.Top,
			Max(0.0f, bounds.Width - inset.TotalHorizontal),
			Max(0.0f, bounds.Height - inset.TotalVertical));
}
