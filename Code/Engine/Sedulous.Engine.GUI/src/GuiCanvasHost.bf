using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Engine.GUI;

/// A canvas's place in its scene's root, filling it (the `canvas` element to a sheet): its
/// document laid out at the root's size, or at the reference resolution and scaled uniformly to
/// fit, centred on a whole pixel. Paints nothing, so it never takes the pointer from the game:
/// only what its document paints does.
class GuiCanvasHost : UIWidget
{
	/// Among the scene's canvases: higher on top.
	public int32 Order = 0;

	private GuiScalerMode mScaler = .ConstantPixel;
	private Float2 mReference = .(0.0f, 0.0f);

	public this()
	{
		Tag = "canvas";
	}

	/// The component's order and scaler; a changed scaler lays the document out again.
	public void Configure(int32 order, GuiScalerMode scaler, Float2 reference)
	{
		Order = order;
		if ((scaler == mScaler) && (reference == mReference))
			return;
		mScaler = scaler;
		mReference = reference;
		RequestLayout();
	}

	public override void OnLayout()
	{
		let size = Size;
		var inner = size;
		var scale = 1.0f;
		var offset = Float2(0.0f, 0.0f);
		if ((mScaler == .ReferenceResolution) && (mReference.X > 0.0f) && (mReference.Y > 0.0f) && (size.X > 0.0f)
			&& (size.Y > 0.0f))
		{
			inner = mReference;
			scale = Math.Min(size.X / inner.X, size.Y / inner.Y);
			offset = .(Math.Round((size.X - inner.X * scale) * 0.5f), Math.Round((size.Y - inner.Y * scale) * 0.5f));
		}
		for (int i < ChildCount)
		{
			// Scaled about its top left, so the drawn rectangle is the offset plus the scaled
			// content, and hit testing undoes the same transform.
			let child = GetChildAt(i);
			child.ScaleOrigin = .(0.0f, 0.0f);
			child.Scale = .(scale, scale);
			child.Arrange(.(offset.X, offset.Y, inner.X, inner.Y));
		}
	}
}
