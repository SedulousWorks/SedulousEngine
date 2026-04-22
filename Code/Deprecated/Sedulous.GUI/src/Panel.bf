using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Base class for layout containers.
/// Panels arrange their children according to specific layout rules.
/// This is the base class for StackPanel, Grid, Canvas, etc.
public class Panel : Container
{
	private Color mBackground = Color.Transparent;

	/// Background color of the panel.
	public Color Background
	{
		get => mBackground;
		set => mBackground = value;
	}

	/// Renders the panel background then children.
	protected override void RenderOverride(DrawContext ctx)
	{
		// Draw background
		if (mBackground.A > 0)
		{
			ctx.FillRect(ArrangedBounds, mBackground);
		}

		// Render children (Container handles ClipToBounds)
		base.RenderOverride(ctx);
	}
}
