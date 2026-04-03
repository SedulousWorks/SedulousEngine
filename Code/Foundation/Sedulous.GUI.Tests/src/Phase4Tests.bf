using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Phase 4 tests: Layout panels.
class Phase4Tests
{
	/// Simple test element with fixed desired size.
	class FixedSizeElement : UIElement
	{
		public float DesiredWidth = 100;
		public float DesiredHeight = 50;

		protected override DesiredSize MeasureOverride(SizeConstraints constraints)
		{
			return .(DesiredWidth, DesiredHeight);
		}
	}

	// ========== StackPanel Tests ==========

	[Test]
	public static void StackPanel_Vertical_StacksChildren()
	{
		let ctx = scope GUIContext();
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Width = 200;
		panel.Height = 300;
		ctx.RootElement = panel;

		let child1 = new FixedSizeElement();
		child1.DesiredWidth = 100;
		child1.DesiredHeight = 40;
		panel.AddChild(child1);

		let child2 = new FixedSizeElement();
		child2.DesiredWidth = 100;
		child2.DesiredHeight = 60;
		panel.AddChild(child2);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Children should be stacked vertically
		Test.Assert(child1.ArrangedBounds.Y < child2.ArrangedBounds.Y);
		Test.Assert(child2.ArrangedBounds.Y == child1.ArrangedBounds.Y + child1.ArrangedBounds.Height);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void StackPanel_Horizontal_StacksChildren()
	{
		let ctx = scope GUIContext();
		let panel = new StackPanel();
		panel.Orientation = .Horizontal;
		panel.Width = 300;
		panel.Height = 100;
		ctx.RootElement = panel;

		let child1 = new FixedSizeElement();
		child1.DesiredWidth = 60;
		child1.DesiredHeight = 40;
		panel.AddChild(child1);

		let child2 = new FixedSizeElement();
		child2.DesiredWidth = 80;
		child2.DesiredHeight = 40;
		panel.AddChild(child2);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Children should be stacked horizontally
		Test.Assert(child1.ArrangedBounds.X < child2.ArrangedBounds.X);
		Test.Assert(child2.ArrangedBounds.X == child1.ArrangedBounds.X + child1.ArrangedBounds.Width);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void StackPanel_WithSpacing()
	{
		let ctx = scope GUIContext();
		let panel = new StackPanel();
		panel.Orientation = .Vertical;
		panel.Spacing = 10;
		panel.Width = 200;
		panel.Height = 300;
		ctx.RootElement = panel;

		let child1 = new FixedSizeElement();
		child1.DesiredHeight = 40;
		panel.AddChild(child1);

		let child2 = new FixedSizeElement();
		child2.DesiredHeight = 40;
		panel.AddChild(child2);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Should have spacing between children
		float expectedY = child1.ArrangedBounds.Y + child1.ArrangedBounds.Height + 10;
		Test.Assert(Math.Abs(child2.ArrangedBounds.Y - expectedY) < 0.1f);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== Canvas Tests ==========

	[Test]
	public static void Canvas_PositionsWithLeft()
	{
		let ctx = scope GUIContext();
		let canvas = new Canvas();
		canvas.Width = 400;
		canvas.Height = 300;
		ctx.RootElement = canvas;

		let child = new FixedSizeElement();
		child.DesiredWidth = 50;
		child.DesiredHeight = 50;
		CanvasProperties.SetLeft(child, 100);
		canvas.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(Math.Abs(child.ArrangedBounds.X - 100) < 0.1f);

		ctx.RootElement = null;
		delete canvas;
	}

	[Test]
	public static void Canvas_PositionsWithTop()
	{
		let ctx = scope GUIContext();
		let canvas = new Canvas();
		canvas.Width = 400;
		canvas.Height = 300;
		ctx.RootElement = canvas;

		let child = new FixedSizeElement();
		child.DesiredWidth = 50;
		child.DesiredHeight = 50;
		CanvasProperties.SetTop(child, 75);
		canvas.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(Math.Abs(child.ArrangedBounds.Y - 75) < 0.1f);

		ctx.RootElement = null;
		delete canvas;
	}

	[Test]
	public static void Canvas_PositionsWithLeftAndTop()
	{
		let ctx = scope GUIContext();
		let canvas = new Canvas();
		canvas.Width = 400;
		canvas.Height = 300;
		ctx.RootElement = canvas;

		let child = new FixedSizeElement();
		child.DesiredWidth = 50;
		child.DesiredHeight = 50;
		CanvasProperties.SetLeft(child, 100);
		CanvasProperties.SetTop(child, 75);
		canvas.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		Test.Assert(Math.Abs(child.ArrangedBounds.X - 100) < 0.1f);
		Test.Assert(Math.Abs(child.ArrangedBounds.Y - 75) < 0.1f);

		ctx.RootElement = null;
		delete canvas;
	}

	// ========== DockPanel Tests ==========

	[Test]
	public static void DockPanel_DocksLeft()
	{
		let ctx = scope GUIContext();
		let panel = new DockPanel();
		panel.Width = 400;
		panel.Height = 300;
		panel.HorizontalAlignment = .Left;
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		let child = new FixedSizeElement();
		child.DesiredWidth = 100;
		child.DesiredHeight = 50;
		child.HorizontalAlignment = .Left;  // Don't stretch
		DockPanelProperties.SetDock(child, .Left);
		panel.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Should be at left edge with desired width
		Test.Assert(child.ArrangedBounds.X == panel.ContentBounds.X);
		Test.Assert(Math.Abs(child.ArrangedBounds.Width - 100) < 0.1f);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void DockPanel_DocksTop()
	{
		let ctx = scope GUIContext();
		let panel = new DockPanel();
		panel.Width = 400;
		panel.Height = 300;
		panel.HorizontalAlignment = .Left;
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		let child = new FixedSizeElement();
		child.DesiredWidth = 50;
		child.DesiredHeight = 80;
		child.VerticalAlignment = .Top;  // Don't stretch
		DockPanelProperties.SetDock(child, .Top);
		panel.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Should be at top edge with desired height
		Test.Assert(child.ArrangedBounds.Y == panel.ContentBounds.Y);
		Test.Assert(Math.Abs(child.ArrangedBounds.Height - 80) < 0.1f);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void DockPanel_LastChildFills()
	{
		let ctx = scope GUIContext();
		let panel = new DockPanel();
		panel.Width = 400;
		panel.Height = 300;
		panel.LastChildFill = true;
		ctx.RootElement = panel;

		let left = new FixedSizeElement();
		left.DesiredWidth = 100;
		DockPanelProperties.SetDock(left, .Left);
		panel.AddChild(left);

		let center = new FixedSizeElement();
		panel.AddChild(center);  // Last child fills

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Center should fill remaining space
		Test.Assert(center.ArrangedBounds.X > left.ArrangedBounds.Right - 1);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== WrapPanel Tests ==========

	[Test]
	public static void WrapPanel_Horizontal_Wraps()
	{
		let ctx = scope GUIContext();
		let panel = new WrapPanel();
		panel.Orientation = .Horizontal;
		panel.Width = 150;  // Only fits 2 items per row
		panel.Height = 200;
		panel.HorizontalAlignment = .Left;
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		// Add 3 items, each 60 wide
		for (int i = 0; i < 3; i++)
		{
			let child = new FixedSizeElement();
			child.DesiredWidth = 60;
			child.DesiredHeight = 40;
			child.HorizontalAlignment = .Left;
			child.VerticalAlignment = .Top;
			panel.AddChild(child);
		}

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Third item should be on second row
		let child1 = panel.GetChild(0);
		let child3 = panel.GetChild(2);
		Test.Assert(child3.ArrangedBounds.Y > child1.ArrangedBounds.Y);

		ctx.RootElement = null;
		delete panel;
	}

	// ========== UniformGrid Tests ==========

	[Test]
	public static void UniformGrid_EqualSizedCells()
	{
		let ctx = scope GUIContext();
		let grid = new UniformGrid();
		grid.Columns = 2;
		grid.Rows = 2;
		grid.Width = 200;
		grid.Height = 200;
		grid.HorizontalAlignment = .Left;
		grid.VerticalAlignment = .Top;
		ctx.RootElement = grid;

		// Add 4 items - they will stretch to fill their cells
		for (int i = 0; i < 4; i++)
		{
			let child = new FixedSizeElement();
			// With Stretch alignment (default), children fill their 100x100 cells
			grid.AddChild(child);
		}

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// All cells should be 100x100 (children stretch to fill)
		for (int i = 0; i < 4; i++)
		{
			let child = grid.GetChild(i);
			Test.Assert(Math.Abs(child.ArrangedBounds.Width - 100) < 0.1f);
			Test.Assert(Math.Abs(child.ArrangedBounds.Height - 100) < 0.1f);
		}

		ctx.RootElement = null;
		delete grid;
	}

	// ========== Grid Tests ==========

	[Test]
	public static void Grid_StarSizing()
	{
		let ctx = scope GUIContext();
		let grid = new Grid();
		grid.Width = 300;
		grid.Height = 200;
		grid.HorizontalAlignment = .Left;
		grid.VerticalAlignment = .Top;

		// Two columns: 1* and 2*
		let col1 = new ColumnDefinition();
		col1.Width = GridLength.Star;
		grid.ColumnDefinitions.Add(col1);

		let col2 = new ColumnDefinition();
		col2.Width = GridLength.StarN(2);
		grid.ColumnDefinitions.Add(col2);

		ctx.RootElement = grid;

		let child1 = new FixedSizeElement();
		GridProperties.SetColumn(child1, 0);
		grid.AddChild(child1);

		let child2 = new FixedSizeElement();
		GridProperties.SetColumn(child2, 1);
		grid.AddChild(child2);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Column 1 should be 100 (1/3 of 300), Column 2 should be 200 (2/3 of 300)
		// Children stretch to fill their cells
		Test.Assert(Math.Abs(child1.ArrangedBounds.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(child2.ArrangedBounds.Width - 200) < 1.0f);

		ctx.RootElement = null;
		delete grid;
	}

	[Test]
	public static void Grid_FixedSizing()
	{
		let ctx = scope GUIContext();
		let grid = new Grid();
		grid.Width = 300;
		grid.Height = 200;
		grid.HorizontalAlignment = .Left;
		grid.VerticalAlignment = .Top;

		// One fixed column (80px) and one star column
		let col1 = new ColumnDefinition();
		col1.Width = GridLength.Pixels(80);
		grid.ColumnDefinitions.Add(col1);

		let col2 = new ColumnDefinition();
		col2.Width = GridLength.Star;
		grid.ColumnDefinitions.Add(col2);

		ctx.RootElement = grid;

		let child1 = new FixedSizeElement();
		GridProperties.SetColumn(child1, 0);
		grid.AddChild(child1);

		let child2 = new FixedSizeElement();
		GridProperties.SetColumn(child2, 1);
		grid.AddChild(child2);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Column 1 should be 80, Column 2 should fill remaining (220)
		Test.Assert(Math.Abs(child1.ArrangedBounds.Width - 80) < 1.0f);
		Test.Assert(Math.Abs(child2.ArrangedBounds.Width - 220) < 1.0f);

		ctx.RootElement = null;
		delete grid;
	}

	[Test]
	public static void Grid_RowAndColumnSpan()
	{
		let ctx = scope GUIContext();
		let grid = new Grid();
		grid.Width = 200;
		grid.Height = 200;
		grid.HorizontalAlignment = .Left;
		grid.VerticalAlignment = .Top;

		// 2x2 grid
		grid.ColumnDefinitions.Add(new ColumnDefinition());
		grid.ColumnDefinitions.Add(new ColumnDefinition());
		grid.RowDefinitions.Add(new RowDefinition());
		grid.RowDefinitions.Add(new RowDefinition());

		ctx.RootElement = grid;

		let child = new FixedSizeElement();
		GridProperties.SetColumn(child, 0);
		GridProperties.SetRow(child, 0);
		GridProperties.SetColumnSpan(child, 2);  // Span both columns
		grid.AddChild(child);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Should span full width (child stretches to fill spanned area)
		Test.Assert(Math.Abs(child.ArrangedBounds.Width - 200) < 1.0f);

		ctx.RootElement = null;
		delete grid;
	}

	// ========== SplitPanel Tests ==========

	[Test]
	public static void SplitPanel_BasicSetup()
	{
		let panel = new SplitPanel();

		// Check splitter exists and has correct properties
		Test.Assert(panel.Splitter != null);
		Test.Assert(panel.SplitterSize == 6);
		Test.Assert(panel.Orientation == .Horizontal);
		Test.Assert(panel.Splitter.Orientation == .Vertical);

		delete panel;
	}

	[Test]
	public static void SplitPanel_HorizontalSplit()
	{
		let ctx = scope GUIContext();
		let panel = new SplitPanel();
		panel.Orientation = .Horizontal;
		panel.SplitRatio = 0.5f;
		panel.SplitterSize = 6;
		panel.Width = 206;  // 100 + 6 + 100
		panel.Height = 100;
		panel.HorizontalAlignment = .Left;
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		let left = new FixedSizeElement();
		panel.AddChild(left);

		let right = new FixedSizeElement();
		panel.AddChild(right);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Left and right should each be ~100 wide (children stretch to fill)
		// Panel content = 206, splitter = 6, available = 200, each side = 100
		Test.Assert(Math.Abs(left.ArrangedBounds.Width - 100) < 1.0f);
		Test.Assert(Math.Abs(right.ArrangedBounds.Width - 100) < 1.0f);
		Test.Assert(right.ArrangedBounds.X > left.ArrangedBounds.Right);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void SplitPanel_VerticalSplit()
	{
		let ctx = scope GUIContext();
		let panel = new SplitPanel();
		panel.Orientation = .Vertical;
		panel.SplitRatio = 0.5f;
		panel.SplitterSize = 6;
		panel.Width = 100;
		panel.Height = 206;  // 100 + 6 + 100
		panel.HorizontalAlignment = .Left;
		panel.VerticalAlignment = .Top;
		ctx.RootElement = panel;

		let top = new FixedSizeElement();
		panel.AddChild(top);

		let bottom = new FixedSizeElement();
		panel.AddChild(bottom);

		ctx.SetViewportSize(800, 600);
		ctx.Update(0, 0);

		// Top and bottom should each be ~100 tall (children stretch to fill)
		Test.Assert(Math.Abs(top.ArrangedBounds.Height - 100) < 1.0f);
		Test.Assert(Math.Abs(bottom.ArrangedBounds.Height - 100) < 1.0f);
		Test.Assert(bottom.ArrangedBounds.Y > top.ArrangedBounds.Bottom);

		ctx.RootElement = null;
		delete panel;
	}
}
