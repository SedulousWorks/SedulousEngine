namespace UISandbox;

using Sedulous.UI;
using Sedulous.Core.Mathematics;
using System;
using System;

/// Demo page: Dialogs, context menus, tooltips.
class OverlaysPage : DemoPage
{
	public this(DemoContext demo) : base(demo)
	{
		AddSection("Dialog");
		{
			let dialogBtn = new Button();
			dialogBtn.SetText("Show Dialog");
			dialogBtn.TooltipText = new String("Opens a modal alert dialog");
			dialogBtn.OnClick.Add(new [&](b) => {
				let dialog = Dialog.Alert("Hello!", "This is a modal dialog.\nPress OK or Escape to close.");
				dialog.Show(mDemo.UI.UIContext);
			});
			mLayout.AddView(dialogBtn, new LinearLayout.LayoutParams() { Height = 36 });
		}

		AddSeparator();
		AddSection("Context Menu (right-click)");
		{
			let copyLabel = new CopyableLabel();
			copyLabel.SetText("Right-click to copy this text");
			mLayout.AddView(copyLabel, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 30 });
		}

		AddSeparator();
		AddSection("Tooltips");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 36 });

			for (let info in scope (TooltipPlacement, StringView)[]((.Bottom, "Bottom"), (.Top, "Top"), (.Left, "Left"), (.Right, "Right")))
			{
				let btn = new Button();
				let text = scope String();
				text.AppendF("Tip: {}", info.1);
				btn.SetText(text);
				btn.TooltipText = new String(text);
				btn.TooltipPlacement = info.0;
				row.AddView(btn, new LinearLayout.LayoutParams() { Height =  Sedulous.UI.LayoutParams.MatchParent });
			}
		}

		// Interactive tooltip
		if (demo.Checkerboard != null)
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 48 });

			let iv = new RichTooltipImageView();
			iv.Image = demo.Checkerboard;
			iv.ScaleType = .FitCenter;
			iv.TooltipImage = demo.Checkerboard;
			iv.TooltipLabel = new String("Interactive tooltip (hover me!)");
			iv.IsTooltipInteractive = true;
			iv.TooltipPlacement = .Right;
			row.AddView(iv, new LinearLayout.LayoutParams() { Width = 48, Height = 48 });

			let desc = new Label();
			desc.SetText("Hover image for rich tooltip");
			desc.VAlign = .Middle;
			row.AddView(desc, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height =  Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });
		}

		AddSeparator();
		AddSection("Custom Theme Controls");
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 26 });

			for (let text in StringView[]("Online", "Active", "Ready"))
			{
				let badge = new StatusBadge();
				badge.SetText(text);
				row.AddView(badge);
			}

			let custom = new StatusBadge();
			custom.SetText("Custom");
			custom.BadgeColor = .(180, 60, 60, 255);
			custom.TooltipText = new String("Explicit color override - ignores theme");
			row.AddView(custom);
		}
	}
}
