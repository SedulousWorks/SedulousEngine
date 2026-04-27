namespace GUISandbox;

using Sedulous.Core.Mathematics;
using Sedulous.GUI;

/// Phase 4: Layout Panel Demos
static class LayoutDemos
{
	public static Panel CreateStackPanel()
	{
		let container = new Panel();
		container.Margin = .(50, 80, 50, 50);

		let vStack = new StackPanel();
		vStack.Orientation = .Vertical;
		vStack.Spacing = 10;
		vStack.Margin = .(20, 20, 20, 20);
		vStack.HorizontalAlignment = .Left;
		vStack.VerticalAlignment = .Top;

		let labelBox = new ColorBox(Color(60, 60, 80, 255), "Vertical Stack");
		labelBox.Width = 200;
		labelBox.Height = 30;
		vStack.AddChild(labelBox);

		let hStack = new StackPanel();
		hStack.Orientation = .Horizontal;
		hStack.Spacing = 15;

		let boxA = new ColorBox(Color(200, 80, 80, 255), "A");
		boxA.Width = 80;
		boxA.Height = 80;
		hStack.AddChild(boxA);

		let boxB = new ColorBox(Color(80, 200, 80, 255), "B");
		boxB.Width = 100;
		boxB.Height = 80;
		hStack.AddChild(boxB);

		let boxC = new ColorBox(Color(80, 80, 200, 255), "C");
		boxC.Width = 60;
		boxC.Height = 80;
		hStack.AddChild(boxC);

		let boxD = new ColorBox(Color(200, 200, 80, 255), "D");
		boxD.Width = 90;
		boxD.Height = 80;
		hStack.AddChild(boxD);

		vStack.AddChild(hStack);

		let hStack2 = new StackPanel();
		hStack2.Orientation = .Horizontal;
		hStack2.Spacing = 10;

		let box2A = new ColorBox(Color(200, 100, 150, 255));
		box2A.Width = 120;
		box2A.Height = 50;
		hStack2.AddChild(box2A);

		let box2B = new ColorBox(Color(100, 200, 150, 255));
		box2B.Width = 120;
		box2B.Height = 50;
		hStack2.AddChild(box2B);

		let box2C = new ColorBox(Color(150, 100, 200, 255));
		box2C.Width = 120;
		box2C.Height = 50;
		hStack2.AddChild(box2C);

		vStack.AddChild(hStack2);

		let boxWide1 = new ColorBox(Color(180, 180, 180, 255));
		boxWide1.Width = 400;
		boxWide1.Height = 40;
		vStack.AddChild(boxWide1);

		let boxWide2 = new ColorBox(Color(140, 140, 140, 255));
		boxWide2.Width = 350;
		boxWide2.Height = 40;
		vStack.AddChild(boxWide2);

		container.AddChild(vStack);
		return container;
	}

	public static Panel CreateGrid()
	{
		let grid = new Grid();
		grid.Margin = .(50, 80, 50, 50);

		let col1 = new ColumnDefinition();
		col1.Width = GridLength.Pixels(100);
		grid.ColumnDefinitions.Add(col1);

		let col2 = new ColumnDefinition();
		col2.Width = GridLength.Star;
		grid.ColumnDefinitions.Add(col2);

		let col3 = new ColumnDefinition();
		col3.Width = GridLength.StarN(2);
		grid.ColumnDefinitions.Add(col3);

		let row1 = new RowDefinition();
		row1.Height = GridLength.Auto;
		grid.RowDefinitions.Add(row1);

		let row2 = new RowDefinition();
		row2.Height = GridLength.Star;
		grid.RowDefinitions.Add(row2);

		let row3 = new RowDefinition();
		row3.Height = GridLength.Pixels(80);
		grid.RowDefinitions.Add(row3);

		let header1 = new ColorBox(Color(80, 80, 120, 255), "100px");
		header1.Height = 40;
		GridProperties.SetRow(header1, 0);
		GridProperties.SetColumn(header1, 0);
		grid.AddChild(header1);

		let header2 = new ColorBox(Color(80, 100, 120, 255), "1*");
		header2.Height = 40;
		GridProperties.SetRow(header2, 0);
		GridProperties.SetColumn(header2, 1);
		grid.AddChild(header2);

		let header3 = new ColorBox(Color(80, 120, 120, 255), "2*");
		header3.Height = 40;
		GridProperties.SetRow(header3, 0);
		GridProperties.SetColumn(header3, 2);
		grid.AddChild(header3);

		let sidebar = new ColorBox(Color(120, 80, 80, 255), "Sidebar");
		GridProperties.SetRow(sidebar, 1);
		GridProperties.SetColumn(sidebar, 0);
		grid.AddChild(sidebar);

		let content = new ColorBox(Color(80, 120, 80, 255), "Content (spans 2 cols)");
		GridProperties.SetRow(content, 1);
		GridProperties.SetColumn(content, 1);
		GridProperties.SetColumnSpan(content, 2);
		grid.AddChild(content);

		let footer = new ColorBox(Color(100, 100, 140, 255), "Footer (spans 3 cols, 80px height)");
		GridProperties.SetRow(footer, 2);
		GridProperties.SetColumn(footer, 0);
		GridProperties.SetColumnSpan(footer, 3);
		grid.AddChild(footer);

		return grid;
	}

	public static Panel CreateCanvas()
	{
		let container = new Panel();
		container.Margin = .(50, 80, 50, 50);

		let canvas = new Canvas();

		let box1 = new ColorBox(Color(200, 80, 80, 255), "Left:20, Top:20");
		box1.Width = 150;
		box1.Height = 80;
		CanvasProperties.SetLeft(box1, 20);
		CanvasProperties.SetTop(box1, 20);
		canvas.AddChild(box1);

		let box2 = new ColorBox(Color(80, 200, 80, 255), "Left:200, Top:50");
		box2.Width = 120;
		box2.Height = 100;
		CanvasProperties.SetLeft(box2, 200);
		CanvasProperties.SetTop(box2, 50);
		canvas.AddChild(box2);

		let box3 = new ColorBox(Color(80, 80, 200, 255), "Right:20, Top:20");
		box3.Width = 140;
		box3.Height = 90;
		CanvasProperties.SetRight(box3, 20);
		CanvasProperties.SetTop(box3, 20);
		canvas.AddChild(box3);

		let box4 = new ColorBox(Color(200, 200, 80, 255), "Left:100, Bottom:30");
		box4.Width = 180;
		box4.Height = 70;
		CanvasProperties.SetLeft(box4, 100);
		CanvasProperties.SetBottom(box4, 30);
		canvas.AddChild(box4);

		let box5 = new ColorBox(Color(200, 80, 200, 255), "Right:50, Bottom:50");
		box5.Width = 100;
		box5.Height = 100;
		CanvasProperties.SetRight(box5, 50);
		CanvasProperties.SetBottom(box5, 50);
		canvas.AddChild(box5);

		let stretched = new ColorBox(Color(80, 200, 200, 255), "Stretched (L:20, R:20)");
		stretched.Height = 40;
		CanvasProperties.SetLeft(stretched, 20);
		CanvasProperties.SetRight(stretched, 20);
		CanvasProperties.SetBottom(stretched, 150);
		canvas.AddChild(stretched);

		container.AddChild(canvas);
		return container;
	}

	public static Panel CreateDockPanel()
	{
		let dock = new DockPanel();
		dock.Margin = .(50, 80, 50, 50);
		dock.LastChildFill = true;

		let header = new ColorBox(Color(80, 80, 140, 255), "Header (Top)");
		header.Height = 60;
		DockPanelProperties.SetDock(header, .Top);
		dock.AddChild(header);

		let footer = new ColorBox(Color(80, 100, 140, 255), "Footer (Bottom)");
		footer.Height = 50;
		DockPanelProperties.SetDock(footer, .Bottom);
		dock.AddChild(footer);

		let leftSidebar = new ColorBox(Color(140, 80, 80, 255), "Left");
		leftSidebar.Width = 120;
		DockPanelProperties.SetDock(leftSidebar, .Left);
		dock.AddChild(leftSidebar);

		let rightPanel = new ColorBox(Color(140, 100, 80, 255), "Right");
		rightPanel.Width = 100;
		DockPanelProperties.SetDock(rightPanel, .Right);
		dock.AddChild(rightPanel);

		let content = new ColorBox(Color(80, 140, 80, 255), "Content (Fill)");
		dock.AddChild(content);

		return dock;
	}

	public static Panel CreateWrapPanel()
	{
		let container = new Panel();
		container.Margin = .(50, 80, 50, 50);

		let wrap = new WrapPanel();
		wrap.Orientation = .Horizontal;
		wrap.Margin = .(10, 10, 10, 10);

		AddWrapItem(wrap, Color(200, 80, 80, 255), 80, 60);
		AddWrapItem(wrap, Color(80, 200, 80, 255), 110, 80);
		AddWrapItem(wrap, Color(80, 80, 200, 255), 140, 60);
		AddWrapItem(wrap, Color(200, 200, 80, 255), 80, 80);
		AddWrapItem(wrap, Color(200, 80, 200, 255), 110, 60);
		AddWrapItem(wrap, Color(80, 200, 200, 255), 140, 80);
		AddWrapItem(wrap, Color(180, 120, 80, 255), 80, 60);
		AddWrapItem(wrap, Color(120, 180, 80, 255), 110, 80);
		AddWrapItem(wrap, Color(80, 120, 180, 255), 140, 60);
		AddWrapItem(wrap, Color(180, 80, 120, 255), 80, 80);
		AddWrapItem(wrap, Color(120, 80, 180, 255), 110, 60);
		AddWrapItem(wrap, Color(80, 180, 120, 255), 140, 80);
		AddWrapItem(wrap, Color(160, 160, 80, 255), 80, 60);
		AddWrapItem(wrap, Color(160, 80, 160, 255), 110, 80);
		AddWrapItem(wrap, Color(80, 160, 160, 255), 140, 60);

		container.AddChild(wrap);
		return container;
	}

	private static void AddWrapItem(WrapPanel wrap, Color color, float width, float height)
	{
		let item = new ColorBox(color);
		item.Width = width;
		item.Height = height;
		item.Margin = .(5, 5, 5, 5);
		wrap.AddChild(item);
	}

	public static Panel CreateSplitPanel()
	{
		let outerSplit = new SplitPanel();
		outerSplit.Margin = .(50, 80, 50, 50);
		outerSplit.Orientation = .Horizontal;
		outerSplit.SplitRatio = 0.3f;
		outerSplit.SplitterSize = 8;
		outerSplit.MinFirstSize = 100;
		outerSplit.MinSecondSize = 200;
		outerSplit.SplitterColor = Color(60, 60, 70, 255);

		let leftPanel = new ColorBox(Color(100, 80, 80, 255), "Left Panel");
		outerSplit.AddChild(leftPanel);

		let innerSplit = new SplitPanel();
		innerSplit.Orientation = .Vertical;
		innerSplit.SplitRatio = 0.6f;
		innerSplit.SplitterSize = 8;
		innerSplit.MinFirstSize = 80;
		innerSplit.MinSecondSize = 80;
		innerSplit.SplitterColor = Color(60, 60, 70, 255);

		let topRight = new ColorBox(Color(80, 100, 80, 255), "Top Right");
		innerSplit.AddChild(topRight);

		let bottomRight = new ColorBox(Color(80, 80, 100, 255), "Bottom Right");
		innerSplit.AddChild(bottomRight);

		outerSplit.AddChild(innerSplit);

		return outerSplit;
	}
}
