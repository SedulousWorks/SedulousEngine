using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Samples.UISandbox;

/// Every container the UI core ships, one after another down a scrolling column.
///
/// They are shown side by side deliberately: the same coloured boxes under six different
/// containers is the only way to see what each one actually decides.
static class LayoutsTab
{
	public static void Build(TabView tabView)
	{
		let scroll = new ScrollView();
		scroll.HScrollBarPolicy.Value = .Never;
		tabView.AddTab("Layouts", scroll);

		let demo = SandboxViews.VFlex(16.0f);
		demo.Padding = .(12);
		{
			LayoutStyle style = .();
			style.Width = SizeSpec.Match();
			scroll.AddView(demo, style);
		}

		AddCaption(demo, "FlexLayout - rows and columns with grow and shrink");
		AddFlex(demo);

		demo.AddView(new Separator());
		AddCaption(demo, "DockLayout - children dock to edges, and the last fills what is left");
		AddDock(demo);

		demo.AddView(new Separator());
		AddCaption(demo, "GridLayout - rows and columns, fixed or flexible, with spans");
		AddGrid(demo);

		demo.AddView(new Separator());
		AddCaption(demo, "FrameLayout - overlapping children placed by gravity");
		AddFrame(demo);

		demo.AddView(new Separator());
		AddCaption(demo, "FlowLayout - children wrap to the next line when the space runs out");
		AddFlow(demo);

		demo.AddView(new Separator());
		AddCaption(demo, "AbsoluteLayout - explicit pixel positions");
		AddAbsolute(demo);
	}

	private static void AddCaption(FlexLayout demo, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.AddClass("label-dim");
		label.FontSize.Value = 12.0f;
		demo.AddView(label);
	}

	private static LayoutStyle GrowSized(float amount, SizeSpec width, SizeSpec height)
	{
		var style = SandboxViews.Grow(amount);
		style.Width = width;
		style.Height = height;
		return style;
	}

	private static void AddFlex(FlexLayout demo)
	{
		let row = SandboxViews.HFlex(4.0f);
		row.AddView(SandboxViews.MakeBox(Color.Rgb(100, 60, 60), "Fixed 80px"),
			SandboxViews.Sized(SizeSpec.Fixed(Unit.Px(80)), SizeSpec.Fixed(Unit.Px(50))));
		row.AddView(SandboxViews.MakeBox(Color.Rgb(60, 100, 60), "Grow 1"),
			GrowSized(1, SizeSpec.Wrap(), SizeSpec.Fixed(Unit.Px(50))));
		row.AddView(SandboxViews.MakeBox(Color.Rgb(60, 60, 100), "Grow 2"),
			GrowSized(2, SizeSpec.Wrap(), SizeSpec.Fixed(Unit.Px(50))));
		demo.AddView(row, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap()));

		let column = SandboxViews.VFlex(4.0f);
		column.AddView(SandboxViews.MakeBox(Color.Rgb(90, 50, 50), "Top"),
			SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(30))));
		column.AddView(SandboxViews.MakeBox(Color.Rgb(50, 90, 50), "Middle (grow)"),
			GrowSized(1, SizeSpec.Match(), SizeSpec.Wrap()));
		column.AddView(SandboxViews.MakeBox(Color.Rgb(50, 50, 90), "Bottom"),
			SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(30))));
		demo.AddView(column, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(120))));
	}

	private static LayoutStyle Docked(Dock edge, SizeSpec width, SizeSpec height)
	{
		var style = SandboxViews.Sized(width, height);
		style.Dock = edge;
		return style;
	}

	private static void AddDock(FlexLayout demo)
	{
		let dock = new DockLayout();
		dock.LastChildFill = true;
		dock.AddView(SandboxViews.MakeBox(Color.Rgb(100, 60, 60), "Top"),
			Docked(.Top, SizeSpec.Wrap(), SizeSpec.Fixed(Unit.Px(30))));
		dock.AddView(SandboxViews.MakeBox(Color.Rgb(60, 60, 100), "Bottom"),
			Docked(.Bottom, SizeSpec.Wrap(), SizeSpec.Fixed(Unit.Px(30))));
		dock.AddView(SandboxViews.MakeBox(Color.Rgb(60, 100, 60), "Left"),
			Docked(.Left, SizeSpec.Fixed(Unit.Px(60)), SizeSpec.Wrap()));
		dock.AddView(SandboxViews.MakeBox(Color.Rgb(100, 100, 60), "Right"),
			Docked(.Right, SizeSpec.Fixed(Unit.Px(60)), SizeSpec.Wrap()));
		dock.AddView(SandboxViews.MakeBox(Color.Rgb(70, 70, 70), "Fill"));
		demo.AddView(dock, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(150))));
	}

	private static LayoutStyle Cell(int32 row, int32 column, int32 columnSpan = 1)
	{
		LayoutStyle style = .();
		style.GridRow = row;
		style.GridColumn = column;
		style.GridColumnSpan = columnSpan;
		return style;
	}

	private static void AddGrid(FlexLayout demo)
	{
		let grid = new GridLayout();
		grid.Columns.Add(TrackSize.Fixed(80));
		grid.Columns.Add(TrackSize.Flex(1));
		grid.Columns.Add(TrackSize.Flex(2));
		for (int i < 3)
			grid.Rows.Add(TrackSize.Fixed(35));

		grid.ColumnSpacing = 4;
		grid.RowSpacing = 4;

		grid.AddView(SandboxViews.MakeBox(Color.Rgb(80, 50, 50), "0,0"), Cell(0, 0));
		grid.AddView(SandboxViews.MakeBox(Color.Rgb(50, 80, 50), "0,1"), Cell(0, 1));
		grid.AddView(SandboxViews.MakeBox(Color.Rgb(50, 50, 80), "0,2"), Cell(0, 2));
		grid.AddView(SandboxViews.MakeBox(Color.Rgb(70, 40, 40), "1,0"), Cell(1, 0));
		grid.AddView(SandboxViews.MakeBox(Color.Rgb(40, 70, 40), "Span 2 cols"), Cell(1, 1, 2));
		grid.AddView(SandboxViews.MakeBox(Color.Rgb(60, 30, 30), "Span 3 cols"), Cell(2, 0, 3));
		demo.AddView(grid, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap()));
	}

	private static LayoutStyle Placed(Gravity gravity)
	{
		LayoutStyle style = .();
		style.Gravity = gravity;
		return style;
	}

	private static void AddFrame(FlexLayout demo)
	{
		let frame = new FrameLayout();
		frame.AddView(SandboxViews.MakeBox(Color.Rgb(40, 40, 40), "Background (Fill)"),
			Placed(.Fill));
		frame.AddView(SandboxViews.MakeBox(Color.Rgb(100, 50, 50), "TopLeft"), Placed(.TopLeft));
		frame.AddView(SandboxViews.MakeBox(Color.Rgb(50, 100, 50), "TopRight"), Placed(.TopRight));
		frame.AddView(SandboxViews.MakeBox(Color.Rgb(50, 50, 100), "Center"), Placed(.Center));
		frame.AddView(SandboxViews.MakeBox(Color.Rgb(100, 100, 50), "BottomLeft"),
			Placed(.BottomLeft));
		frame.AddView(SandboxViews.MakeBox(Color.Rgb(100, 50, 100), "BottomRight"),
			Placed(.BottomRight));
		demo.AddView(frame, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(140))));
	}

	private static void AddFlow(FlexLayout demo)
	{
		let flow = new FlowLayout();
		flow.HSpacing = 4.0f;
		flow.VSpacing = 4.0f;

		StringView[15] tags = .("Fire", "Water", "Earth", "Wind", "Electric", "Dark", "Light",
			"Neutral", "Poison", "Burn", "Stun", "Freeze", "Shield", "Heal", "Speed Up");
		Color[15] colors = .(
			Color.Rgb(140, 50, 50), Color.Rgb(50, 80, 140), Color.Rgb(60, 100, 40),
			Color.Rgb(70, 130, 130), Color.Rgb(130, 120, 40), Color.Rgb(80, 50, 100),
			Color.Rgb(130, 120, 80), Color.Rgb(80, 80, 80), Color.Rgb(100, 60, 120),
			Color.Rgb(140, 70, 30), Color.Rgb(120, 100, 30), Color.Rgb(40, 100, 130),
			Color.Rgb(50, 100, 100), Color.Rgb(50, 120, 50), Color.Rgb(30, 100, 130));

		for (int i < 15)
			flow.AddView(SandboxViews.MakeBox(colors[i], tags[i]));

		demo.AddView(flow, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Wrap()));
	}

	private static LayoutStyle At(float x, float y)
	{
		LayoutStyle style = .();
		style.Left = .(x, true);
		style.Top = .(y, true);
		return style;
	}

	private static void AddAbsolute(FlexLayout demo)
	{
		let absolute = new AbsoluteLayout();
		absolute.AddView(SandboxViews.MakeBox(Color.Rgb(60, 60, 60), "x:0 y:0"), At(0, 0));
		absolute.AddView(SandboxViews.MakeBox(Color.Rgb(100, 50, 50), "x:100 y:10"), At(100, 10));
		absolute.AddView(SandboxViews.MakeBox(Color.Rgb(50, 100, 50), "x:50 y:60"), At(50, 60));
		absolute.AddView(SandboxViews.MakeBox(Color.Rgb(50, 50, 100), "x:200 y:40"), At(200, 40));
		demo.AddView(absolute, SandboxViews.Sized(SizeSpec.Match(), SizeSpec.Fixed(Unit.Px(110))));
	}
}
