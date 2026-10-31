using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// The three scroll bar arrangements side by side: bars floating over the content, bars
/// reserving their own strip, and a horizontal strip that is always there.
///
/// What the three columns show is that the MODE changes the content's width and the POLICY only
/// changes whether a bar appears.
static class ScrollViewTab
{
	public static void Build(TabView tabView)
	{
		let body = SandboxViews.HFlex(8.0f);
		body.Padding = .(12, 8);
		tabView.AddTab("ScrollView", body);

		AddColumn(body, "Overlay Mode", .Overlay, .Auto, .Auto, false, 30);
		AddColumn(body, "Reserved Mode", .Reserved, .Auto, .Auto, false, 30);
		AddColumn(body, "Horizontal", .Reserved, .Always, .Always, true, 20);
	}

	private static void AddColumn(FlexLayout body, StringView title, ScrollBarMode mode,
		ScrollBarPolicy vertical, ScrollBarPolicy horizontal, bool acrossTheRow, int32 count)
	{
		let column = SandboxViews.VFlex(4.0f);

		let caption = new Label();
		caption.SetText(title);
		column.AddView(caption);

		let scroll = new ScrollView();
		scroll.ScrollBarMode.Value = mode;
		scroll.VScrollBarPolicy.Value = vertical;
		scroll.HScrollBarPolicy.Value = horizontal;

		let content = acrossTheRow ? SandboxViews.HFlex(4.0f) : SandboxViews.VFlex(4.0f);
		for (int32 i < count)
		{
			if (acrossTheRow)
			{
				content.AddView(new ColorView(
					Color.Rgb((uint8)(60 + (i * 9)), (uint8)(100 + (i * 5)),
						(uint8)(180 - (i * 6))), 60.0f, 60.0f));
			}
			else
			{
				let row = new Label();
				row.SetText(scope $"{title} {i + 1}");
				content.AddView(row);
			}
		}

		scroll.AddView(content);
		column.AddView(scroll, SandboxViews.Grow(1));
		body.AddView(column, SandboxViews.Grow(1));
	}
}
