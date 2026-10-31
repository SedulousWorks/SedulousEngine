using System;
using Sedulous.Core;
using System.Collections;
using Sedulous.Image;
using Sedulous.UI;

namespace Samples.UISandbox;

/// The handful of view shorthands every tab builder reaches for.
///
/// The sandbox builds its tree in code rather than in markup, so these keep the builders
/// readable: without them every row is three statements of layout bookkeeping.
static class SandboxViews
{
	public static LayoutStyle Sized(SizeSpec width, SizeSpec height)
	{
		LayoutStyle style = .();
		style.Width = width;
		style.Height = height;
		return style;
	}

	public static LayoutStyle Grow(float amount)
	{
		LayoutStyle style = .();
		style.FlexGrow = amount;
		return style;
	}

	public static FlexLayout VFlex(float spacing = 0.0f)
	{
		let flex = new FlexLayout();
		flex.Direction = .Vertical;
		flex.Spacing = spacing;
		return flex;
	}

	public static FlexLayout HFlex(float spacing = 0.0f)
	{
		let flex = new FlexLayout();
		flex.Direction = .Horizontal;
		flex.Spacing = spacing;
		return flex;
	}

	/// A coloured box with a centred caption, which is what the layout tabs are made of.
	public static Panel MakeBox(Color color, StringView text)
	{
		let panel = new Panel();
		panel.SetStyle(.Background, new ColorDrawable(color));
		panel.Padding = .(8, 4, 8, 4);

		let label = new Label();
		label.SetText(text);
		label.FontSize.Value = 11.0f;
		label.HAlign.Value = .Center;
		label.VAlign.Value = .Middle;
		panel.AddView(label);
		return panel;
	}

	/// A 64 by 64 checkerboard in two blues, for the image and drawable demos.
	public static OwnedImageData MakeCheckerboard()
	{
		const int32 cSize = 64;
		const int32 cCell = 8;

		let pixels = new List<uint8>();
		pixels.Resize(cSize * cSize * 4);

		uint8[4] light = .(100, 140, 200, 255);
		uint8[4] dark = .(40, 50, 70, 255);

		for (int32 y < cSize)
		{
			for (int32 x < cSize)
			{
				let offset = ((y * cSize) + x) * 4;
				let isLight = (((x / cCell) + (y / cCell)) % 2) == 0;
				for (int c < 4)
					pixels[offset + c] = isLight ? light[c] : dark[c];
			}
		}

		// TAKES the list.
		return new OwnedImageData(cSize, cSize, .RGBA8, pixels);
	}
}
