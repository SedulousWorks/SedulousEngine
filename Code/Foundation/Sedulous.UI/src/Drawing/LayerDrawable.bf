namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Stacks multiple drawables with per-layer insets, drawn in order.
public class LayerDrawable : Drawable
{
	public struct Layer
	{
		public Drawable Drawable;
		public Thickness Inset;
	}

	private List<Layer> mLayers = new .() ~ delete _;

	public this() {}

	public ~this()
	{
		for (let layer in mLayers)
			layer.Drawable?.ReleaseRef();
	}

	/// Consumes the caller's ref on `drawable` - no AddRef. The layer
	/// is released when this LayerDrawable is freed.
	public void AddLayer(Drawable drawable, Thickness inset = .())
	{
		mLayers.Add(.() { Drawable = drawable, Inset = inset });
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		for (let layer in mLayers)
		{
			if (layer.Drawable == null) continue;
			let inset = layer.Inset;
			let layerBounds = RectangleF(
				bounds.X + inset.Left,
				bounds.Y + inset.Top,
				Math.Max(0, bounds.Width - inset.TotalHorizontal),
				Math.Max(0, bounds.Height - inset.TotalVertical));
			layer.Drawable.Draw(ctx, layerBounds);
		}
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds, ControlState state)
	{
		for (let layer in mLayers)
		{
			if (layer.Drawable == null) continue;
			let inset = layer.Inset;
			let layerBounds = RectangleF(
				bounds.X + inset.Left,
				bounds.Y + inset.Top,
				Math.Max(0, bounds.Width - inset.TotalHorizontal),
				Math.Max(0, bounds.Height - inset.TotalVertical));
			layer.Drawable.Draw(ctx, layerBounds, state);
		}
	}
}
