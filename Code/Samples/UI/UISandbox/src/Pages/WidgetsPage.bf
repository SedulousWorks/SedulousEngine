namespace UISandbox;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Demo page: Labels, buttons, panel, drawables, images, flow/absolute/grid layouts.
class WidgetsPage : DemoPage
{
	public this(DemoContext demo) : base(demo)
	{
		AddSection("Labels & Buttons");

		// Label
		{
			let label = new Label();
			label.SetText("Label — 16px Roboto (theme color)");
			label.TooltipText = new String("Tooltip: Right placement");
			label.TooltipPlacement = .Right;
			mLayout.AddView(label, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 22 });
		}

		// Colored buttons
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 36 });
			AddButton(row, "Primary", .(50, 100, 200, 255), "Tooltip: Bottom (default)", .Bottom);
			AddButton(row, "Success", .(50, 160, 70, 255), "Tooltip: Top placement", .Top);
			AddButton(row, "Danger", .(200, 60, 60, 255), "Tooltip: Left placement", .Left);
		}

		// Theme buttons
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 36 });

			for (let text in StringView[]("Theme Btn 1", "Theme Btn 2"))
			{
				let btn = new Button();
				btn.SetText(text);
				btn.OnClick.Add(new [&](b) => {
					if (mDemo.ClickLabel != null)
					{
						let msg = scope String();
						msg.AppendF("Clicked: {}", b.Text);
						mDemo.ClickLabel.SetText(msg);
					}
				});
				row.AddView(btn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
			}
		}

		// Click feedback
		{
			mDemo.ClickLabel = new Label();
			mDemo.ClickLabel.SetText("Click / Tab / F5=toggle theme");
			mLayout.AddView(mDemo.ClickLabel, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 20 });
		}

		// Panel
		{
			let panel = new Panel();
			panel.Padding = .(10, 6);
			panel.TooltipText = new String("Panel with theme-driven background and border");
			mLayout.AddView(panel, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 40 });
			let panelLabel = new Label();
			panelLabel.SetText("Panel (theme background)");
			panel.AddView(panelLabel, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
		}

		AddSeparator();
		AddSection("FlowLayout");

		{
			let flow = new FlowLayout();
			flow.Orientation = .Horizontal;
			flow.HSpacing = 4;
			flow.VSpacing = 4;
			mLayout.AddView(flow, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 70 });
			for (int i = 0; i < 16; i++)
			{
				let chip = new ColorView();
				chip.Color = HSLToColor((float)i / 16.0f, 0.6f, 0.45f);
				chip.PreferredWidth = 36;
				chip.PreferredHeight = 26;
				flow.AddView(chip);
			}
		}

		AddSeparator();
		AddSection("Drawables & Images");

		// Drawable grid
		if (demo.Checkerboard != null)
		{
			let grid = new GridLayout();
			grid.ColumnDefs.Add(.Star(1));
			grid.ColumnDefs.Add(.Star(1));
			grid.RowDefs.Add(.Star(1));
			grid.RowDefs.Add(.Star(1));
			grid.HSpacing = 6;
			grid.VSpacing = 6;
			mLayout.AddView(grid, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 110 });

			let gradPanel = new Panel();
			gradPanel.Background = new GradientDrawable(.(80, 40, 180, 255), .(40, 160, 200, 255), .TopToBottom);
			grid.AddView(gradPanel, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

			let imgPanel = new Panel();
			imgPanel.Background = new ImageDrawable(demo.Checkerboard);
			grid.AddView(imgPanel, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

			let layered = new LayerDrawable();
			layered.AddLayer(new GradientDrawable(.(40, 80, 60, 255), .(20, 40, 80, 255), .LeftToRight));
			layered.AddLayer(new RoundedRectDrawable(.Transparent, 4, .(120, 200, 140, 255), 2));
			let layerPanel = new Panel();
			layerPanel.Background = layered;
			grid.AddView(layerPanel, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

			let shapePanel = new Panel();
			shapePanel.Background = new ShapeDrawable(new (ctx, bounds) => {
				ctx.VG.FillRect(bounds, .(40, 40, 50, 255));
				ctx.VG.DrawLine(.(bounds.X, bounds.Y), .(bounds.X + bounds.Width, bounds.Y + bounds.Height), .(255, 100, 100, 200), 2);
				ctx.VG.DrawLine(.(bounds.X + bounds.Width, bounds.Y), .(bounds.X, bounds.Y + bounds.Height), .(255, 100, 100, 200), 2);
			});
			grid.AddView(shapePanel, new GridLayout.LayoutParams() { Row = 1, Column = 1 });
		}

		// DockView layout
		AddSection("DockView");
		{
			let dockView = new DockView();
			mLayout.AddView(dockView, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 150 });

			let top = new Panel();
			top.Background = new ColorDrawable(.(60, 130, 200, 255));
			let topLabel = new Label();
			topLabel.SetText("Top (Menu Bar)");
			topLabel.FontSize = 11;
			topLabel.HAlign = .Center;
			topLabel.VAlign = .Middle;
			top.AddView(topLabel, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
			dockView.AddView(top, new DockView.LayoutParams(.Top) { Height = 24 });

			let bottom = new Panel();
			bottom.Background = new ColorDrawable(.(60, 130, 200, 255));
			let bottomLabel = new Label();
			bottomLabel.SetText("Bottom (Status Bar)");
			bottomLabel.FontSize = 11;
			bottomLabel.HAlign = .Center;
			bottomLabel.VAlign = .Middle;
			bottom.AddView(bottomLabel, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
			dockView.AddView(bottom, new DockView.LayoutParams(.Bottom) { Height = 20 });

			let left = new Panel();
			left.Background = new ColorDrawable(.(80, 160, 80, 255));
			let leftLabel = new Label();
			leftLabel.SetText("Left");
			leftLabel.FontSize = 11;
			leftLabel.HAlign = .Center;
			leftLabel.VAlign = .Middle;
			left.AddView(leftLabel, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
			dockView.AddView(left, new DockView.LayoutParams(.Left) { Width = 80 });

			let center = new Panel();
			center.Background = new ColorDrawable(.(50, 50, 60, 255));
			let centerLabel = new Label();
			centerLabel.SetText("Fill (Content)");
			centerLabel.FontSize = 11;
			centerLabel.HAlign = .Center;
			centerLabel.VAlign = .Middle;
			center.AddView(centerLabel, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
			dockView.AddView(center, new DockView.LayoutParams(.Fill));
		}

		// Image ScaleType
		if (demo.Checkerboard != null)
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			mLayout.AddView(row, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 50 });

			ScaleType[?] scaleTypes = .(.None, .FitCenter, .FillBounds, .CenterCrop);
			StringView[?] scaleNames = .("None", "FitCenter", "FillBounds", "CenterCrop");

			for (int si = 0; si < scaleTypes.Count; si++)
			{
				let panel = new Panel();
				panel.Padding = .(1);
				row.AddView(panel, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent, Weight = 1 });

				let iv = new ImageView();
				iv.Image = demo.Checkerboard;
				iv.ScaleType = scaleTypes[si];
				iv.TooltipText = new String(scaleNames[si]);
				iv.TooltipPlacement = .Top;
				panel.AddView(iv, new Sedulous.UI.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = Sedulous.UI.LayoutParams.MatchParent });
			}
		}
	}

	private void AddButton(LinearLayout row, StringView text, Color bgColor, StringView tooltip, TooltipPlacement placement)
	{
		let btn = new Button();
		btn.SetText(text);
		if (tooltip.Length > 0)
		{
			btn.TooltipText = new String(tooltip);
			btn.TooltipPlacement = placement;
		}

		let bg = new StateListDrawable();
		bg.Set(.Normal, new RoundedRectDrawable(bgColor, 4));
		bg.Set(.Hover, new RoundedRectDrawable(Palette.Lighten(bgColor, 0.15f), 4));
		bg.Set(.Pressed, new RoundedRectDrawable(Palette.Darken(bgColor, 0.15f), 4));
		btn.Background = bg;

		btn.OnClick.Add(new [&](clickedBtn) => {
			if (mDemo.ClickLabel != null)
			{
				let msg = scope String();
				msg.AppendF("Clicked: {}", clickedBtn.Text);
				mDemo.ClickLabel.SetText(msg);
			}
		});

		row.AddView(btn, new LinearLayout.LayoutParams() { Height = Sedulous.UI.LayoutParams.MatchParent });
	}

	private static Color HSLToColor(float h, float s, float l)
	{
		float c = (1 - Math.Abs(2 * l - 1)) * s;
		float x = c * (1 - Math.Abs((h * 6) % 2 - 1));
		float m = l - c / 2;
		float r = 0, g = 0, b = 0;
		if (h < 1.0f / 6) { r = c; g = x; }
		else if (h < 2.0f / 6) { r = x; g = c; }
		else if (h < 3.0f / 6) { g = c; b = x; }
		else if (h < 4.0f / 6) { g = x; b = c; }
		else if (h < 5.0f / 6) { r = x; b = c; }
		else { r = c; b = x; }
		return .((uint8)((r + m) * 255), (uint8)((g + m) * 255), (uint8)((b + m) * 255), 255);
	}
}
