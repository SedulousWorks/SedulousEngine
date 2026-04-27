namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// A focusable colored rectangle control for testing input and focus.
class FocusableRect : Control
{
	public Color RectColor = Color(100, 150, 200, 255);

	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		return .(100, 80);
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		let bgColor = GetStateBackground();
		ctx.FillRect(ArrangedBounds, bgColor);

		let borderColor = GetStateBorderColor();
		let borderThickness = GetStateBorderThickness();
		if (borderThickness > 0)
		{
			ctx.DrawRect(ArrangedBounds, borderColor, borderThickness);
		}
	}

	protected override Color GetStateBackground()
	{
		switch (CurrentState)
		{
		case .Disabled:
			return Color((uint8)(RectColor.R / 2), (uint8)(RectColor.G / 2), (uint8)(RectColor.B / 2), RectColor.A);
		case .Pressed:
			return Color(
				(uint8)Math.Min(255, (int)(RectColor.R * 0.7f)),
				(uint8)Math.Min(255, (int)(RectColor.G * 0.7f)),
				(uint8)Math.Min(255, (int)(RectColor.B * 0.7f)),
				RectColor.A);
		case .Hover:
			return Color(
				(uint8)Math.Min(255, RectColor.R + 30),
				(uint8)Math.Min(255, RectColor.G + 30),
				(uint8)Math.Min(255, RectColor.B + 30),
				RectColor.A);
		case .Focused:
			return Color(
				(uint8)Math.Min(255, RectColor.R + 15),
				(uint8)Math.Min(255, RectColor.G + 15),
				(uint8)Math.Min(255, RectColor.B + 15),
				RectColor.A);
		default:
			return RectColor;
		}
	}
}

/// A focusable rectangle that uses theme colors (no explicit colors set).
class ThemedRect : Control
{
	public this()
	{
		IsFocusable = true;
		IsTabStop = true;
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		return .(100, 80);
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		let bgColor = GetStateBackground();
		ctx.FillRect(ArrangedBounds, bgColor);

		let borderColor = GetStateBorderColor();
		let borderThickness = GetStateBorderThickness();
		if (borderThickness > 0)
		{
			ctx.DrawRect(ArrangedBounds, borderColor, borderThickness);
		}
	}
}

/// A simple panel for Phase 3 demo.
class DemoPanel : Panel
{
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		float x = contentBounds.X + 20;
		float y = contentBounds.Y + 20;
		float spacing = 20;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChild(i);
			if (child == null || child.Visibility == .Collapsed)
				continue;

			let desiredSize = child.DesiredSize;
			child.Arrange(.(x, y, desiredSize.Width, desiredSize.Height));
			x += desiredSize.Width + spacing;
		}
	}
}

/// A simple colored box control for layout demos.
class ColorBox : Control
{
	public Color BoxColor = Color(100, 150, 200, 255);
	public String Label ~ delete _;

	public this(Color color, StringView label = "")
	{
		BoxColor = color;
		if (!label.IsEmpty)
			Label = new String(label);
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		return .(80, 60);
	}

	protected override void RenderOverride(DrawContext ctx)
	{
		ctx.FillRect(ArrangedBounds, BoxColor);
		ctx.DrawRect(ArrangedBounds, Color(40, 40, 40, 255), 1);
	}
}

/// Enumeration of demos.
enum DemoType
{
	case FocusAndTheme;
	case StackPanel;
	case Grid;
	case Canvas;
	case DockPanel;
	case WrapPanel;
	case SplitPanel;
	case DisplayControls;
	case InteractiveControls;
	case TextInput;
	case Scrolling;
	case ListControls;
	case TabNavigation;
	case TreeView;
	case PopupDialog;
	case DragDrop;
	case MenuToolbar;
	case Docking;
	case DataDisplay;
	case Animation;
	case Tooltips;
}
