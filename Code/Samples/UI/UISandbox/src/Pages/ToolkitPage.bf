namespace UISandbox;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

/// Demo page: Toolkit controls - SplitView, Toolbar, MenuBar, StatusBar,
/// PropertyGrid, ColorPicker.
class ToolkitPage : DemoPage
{
	public this(DemoContext demo) : base(demo)
	{
		AddSection("SplitView");
		{
			let split = new SplitView();
			split.Orientation = .Horizontal;
			split.SplitRatio = 0.4f;
			split.MinPaneSize = 40;

			let leftPane = new FrameLayout();
			leftPane.Padding = .(8, 4);
			let leftLabel = new Label(); leftLabel.SetText("Left pane"); leftLabel.FontSize = 12;
			leftPane.AddView(leftLabel);

			let rightPane = new FrameLayout();
			rightPane.Padding = .(8, 4);
			let rightLabel = new Label(); rightLabel.SetText("Right pane (drag divider)"); rightLabel.FontSize = 12;
			rightPane.AddView(rightLabel);

			split.SetPanes(leftPane, rightPane);
			mLayout.AddView(split, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 60 });
		}

		AddSeparator();
		AddSection("Toolbar");
		{
			let toolbar = new Toolbar();
			let btn1 = toolbar.AddButton("File");
			btn1.OnClick.Add(new (b) => { mDemo.ClickLabel?.SetText("File clicked"); });
			let btn2 = toolbar.AddButton("Edit");
			btn2.OnClick.Add(new (b) => { mDemo.ClickLabel?.SetText("Edit clicked"); });
			toolbar.AddSeparator();
			let toggle = toolbar.AddToggle("Grid");
			toggle.OnCheckedChanged.Add(new (t, v) => {
				let msg = scope String();
				msg.AppendF("Grid: {}", v ? "ON" : "OFF");
				mDemo.ClickLabel?.SetText(msg);
			});
			mLayout.AddView(toolbar, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 30 });
		}

		AddSeparator();
		AddSection("MenuBar");
		{
			let menuBar = new MenuBar();
			let fileMenu = menuBar.AddMenu("File");
			fileMenu.AddItem("New", new () => { mDemo.ClickLabel?.SetText("File > New"); });
			fileMenu.AddItem("Open", new () => { mDemo.ClickLabel?.SetText("File > Open"); });
			fileMenu.AddSeparator();
			fileMenu.AddItem("Exit", new () => { mDemo.ClickLabel?.SetText("File > Exit"); });

			let editMenu = menuBar.AddMenu("Edit");
			editMenu.AddItem("Undo", new () => { mDemo.ClickLabel?.SetText("Edit > Undo"); });
			editMenu.AddItem("Redo", new () => { mDemo.ClickLabel?.SetText("Edit > Redo"); });

			mLayout.AddView(menuBar, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 28 });
		}

		AddSeparator();
		AddSection("StatusBar");
		{
			let statusBar = new StatusBar();
			statusBar.SetText("Ready");
			statusBar.AddSection("Ln 1, Col 1");
			statusBar.AddSection("UTF-8");
			mLayout.AddView(statusBar, new LinearLayout.LayoutParams() { Width =  Sedulous.UI.LayoutParams.MatchParent, Height = 24 });
		}

		AddSeparator();
		AddSection("PropertyGrid");
		{
			let grid = new PropertyGrid();
			grid.AddProperty(new BoolEditor("Visible", true));
			grid.AddProperty(new StringEditor("Name", "Player"));
			grid.AddProperty(new FloatEditor("Speed", 5.0, 0, 100, 0.5, 1, category: "Physics"));
			grid.AddProperty(new IntEditor("Health", 100, 0, 999, category: "Stats"));
			grid.AddProperty(new RangeEditor("Volume", 0.8f, 0, 1, category: "Audio"));
			grid.AddProperty(new ColorEditor("Tint", .(200, 100, 50, 255)));
			mLayout.AddView(grid, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 200 });
		}

		AddSeparator();
		AddSection("ColorPicker");
		{
			let picker = new ColorPicker();
			picker.SetColor(.(100, 180, 220, 255));
			mLayout.AddView(picker, new LinearLayout.LayoutParams() { Width = Sedulous.UI.LayoutParams.MatchParent, Height = 200 });
		}
	}
}
