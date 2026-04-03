namespace GUISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.GUI;

/// Demo 10: Scrolling and Range Controls
/// Shows ScrollViewer, Slider, and Splitter functionality.
class ScrollingDemo
{
	private StackPanel mRoot /*~ delete _*/;
	private TextBlock mSliderValueLabel /*~ delete _*/;
	private TextBlock mScrollInfoLabel /*~ delete _*/;
	private Slider mMainSlider;
	private Splitter mSplitter;
	private Panel mLeftPanel;
	private Panel mRightPanel;
	private float mSplitterPosition = 300;

	public UIElement CreateDemo()
	{
		mRoot = new StackPanel();
		mRoot.Orientation = .Vertical;
		mRoot.Spacing = 15;
		mRoot.Padding = .(20, 20, 20, 20);

		// Title
		let title = new TextBlock("Scrolling & Range Controls Demo");
		title.FontSize = 20;
		mRoot.AddChild(title);

		// Slider section
		CreateSliderSection();

		// ScrollViewer section
		CreateScrollViewerSection();

		// Splitter section
		CreateSplitterSection();

		return mRoot;
	}

	private void CreateSliderSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Sliders");
		header.FontSize = 16;
		section.AddChild(header);

		// Horizontal slider with value display
		let hSliderRow = new StackPanel();
		hSliderRow.Orientation = .Horizontal;
		hSliderRow.Spacing = 15;

		let hSliderLabel = new TextBlock("Value:");
		hSliderRow.AddChild(hSliderLabel);

		mMainSlider = new Slider();
		mMainSlider.Minimum = 0;
		mMainSlider.Maximum = 100;
		mMainSlider.Value = 50;
		mMainSlider.Width = 250;
		mMainSlider.TickFrequency = 10;
		mMainSlider.TickPlacement = .BottomRight;
		mMainSlider.ValueChanged.Subscribe(new (s, v) => {
			mSliderValueLabel.Text = scope $"{v:F1}";
		});
		hSliderRow.AddChild(mMainSlider);

		mSliderValueLabel = new TextBlock("50.0");
		mSliderValueLabel.Width = 50;
		hSliderRow.AddChild(mSliderValueLabel);

		section.AddChild(hSliderRow);

		// Stepped slider
		let steppedRow = new StackPanel();
		steppedRow.Orientation = .Horizontal;
		steppedRow.Spacing = 15;

		let stepLabel = new TextBlock("Step 10:");
		steppedRow.AddChild(stepLabel);

		let steppedSlider = new Slider();
		steppedSlider.Minimum = 0;
		steppedSlider.Maximum = 100;
		steppedSlider.Value = 30;
		steppedSlider.Step = 10;
		steppedSlider.Width = 250;
		steppedSlider.TickFrequency = 10;
		steppedSlider.TickPlacement = .Both;
		steppedRow.AddChild(steppedSlider);

		let stepValueLabel = new TextBlock("30");
		stepValueLabel.Width = 50;
		steppedSlider.ValueChanged.Subscribe(new (s, v) => {
			stepValueLabel.Text = scope $"{(int)v}";
		});
		steppedRow.AddChild(stepValueLabel);

		section.AddChild(steppedRow);

		// Vertical slider
		let vertRow = new StackPanel();
		vertRow.Orientation = .Horizontal;
		vertRow.Spacing = 20;

		let vertLabel = new TextBlock("Vertical:");
		vertRow.AddChild(vertLabel);

		let vertSlider = new Slider();
		vertSlider.Orientation = .Vertical;
		vertSlider.Minimum = 0;
		vertSlider.Maximum = 100;
		vertSlider.Value = 75;
		vertSlider.Height = 100;
		vertSlider.TickFrequency = 25;
		vertSlider.TickPlacement = .TopLeft;
		vertRow.AddChild(vertSlider);

		let vertValueLabel = new TextBlock("75");
		vertSlider.ValueChanged.Subscribe(new (s, v) => {
			vertValueLabel.Text = scope $"{(int)v}";
		});
		vertRow.AddChild(vertValueLabel);

		section.AddChild(vertRow);

		mRoot.AddChild(section);
	}

	private void CreateScrollViewerSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("ScrollViewer");
		header.FontSize = 16;
		section.AddChild(header);

		// Scroll info
		mScrollInfoLabel = new TextBlock("Scroll: (0, 0)");
		section.AddChild(mScrollInfoLabel);

		// ScrollViewer with large content
		let scrollViewer = new ScrollViewer();
		scrollViewer.Width = 400;
		scrollViewer.Height = 150;
		scrollViewer.HorizontalScrollBarVisibility = .Auto;
		scrollViewer.VerticalScrollBarVisibility = .Auto;
		scrollViewer.ScrollChanged.Subscribe(new (sv) => {
			mScrollInfoLabel.Text = scope $"Scroll: ({sv.HorizontalOffset:F0}, {sv.VerticalOffset:F0}) / Extent: ({sv.ExtentWidth:F0}x{sv.ExtentHeight:F0})";
		});

		// Large content panel
		let content = new Canvas();
		content.Width = 800;
		content.Height = 400;
		content.Background = Color(25, 25, 25, 255);

		// Add some colored boxes at various positions
		for (int row = 0; row < 4; row++)
		{
			for (int col = 0; col < 8; col++)
			{
				let colorBox = new Panel();
				colorBox.Width = 80;
				colorBox.Height = 80;
				colorBox.Background = Color(
					(uint8)(50 + col * 25),
					(uint8)(50 + row * 50),
					(uint8)(150 - col * 10),
					255
				);
				CanvasProperties.SetLeft(colorBox, 10 + col * 95);
				CanvasProperties.SetTop(colorBox, 10 + row * 95);
				content.AddChild(colorBox);
			}
		}

		scrollViewer.Content = content;
		section.AddChild(scrollViewer);

		// Scroll buttons
		let buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 10;

		let topBtn = new Button("Top");
		topBtn.Click.Subscribe(new (b) => scrollViewer.ScrollToTop());
		buttonRow.AddChild(topBtn);

		let bottomBtn = new Button("Bottom");
		bottomBtn.Click.Subscribe(new (b) => scrollViewer.ScrollToBottom());
		buttonRow.AddChild(bottomBtn);

		let leftBtn = new Button("Left");
		leftBtn.Click.Subscribe(new (b) => scrollViewer.ScrollToLeft());
		buttonRow.AddChild(leftBtn);

		let rightBtn = new Button("Right");
		rightBtn.Click.Subscribe(new (b) => scrollViewer.ScrollToRight());
		buttonRow.AddChild(rightBtn);

		section.AddChild(buttonRow);

		mRoot.AddChild(section);
	}

	private void CreateSplitterSection()
	{
		let section = new StackPanel();
		section.Orientation = .Vertical;
		section.Spacing = 10;
				section.Padding = .(15, 15, 15, 15);

		let header = new TextBlock("Splitter (drag the bar to resize)");
		header.FontSize = 16;
		section.AddChild(header);

		// Custom layout container for splitter
		let splitContainer = new SplitterContainer();
		splitContainer.Width = 600;
		splitContainer.Height = 100;

		// Left panel
		mLeftPanel = new Panel();
		mLeftPanel.Background = Color(60, 80, 100, 255);
		mLeftPanel.ClipToBounds = true;
		let leftLabel = new TextBlock("Left Panel");
		leftLabel.Margin = .(10, 10, 10, 10);
		mLeftPanel.AddChild(leftLabel);
		splitContainer.AddChild(mLeftPanel);

		// Splitter
		mSplitter = new Splitter(.Vertical);
		mSplitter.Thickness = 6;
		mSplitter.SplitterMoved.Subscribe(new (s, delta) => {
			mSplitterPosition = Math.Clamp(mSplitterPosition + delta, 50, 550);
			splitContainer.SplitterPosition = mSplitterPosition;
			splitContainer.InvalidateLayout();
		});
		splitContainer.AddChild(mSplitter);

		// Right panel
		mRightPanel = new Panel();
		mRightPanel.Background = Color(100, 60, 80, 255);
		mRightPanel.ClipToBounds = true;
		let rightLabel = new TextBlock("Right Panel");
		rightLabel.Margin = .(10, 10, 10, 10);
		mRightPanel.AddChild(rightLabel);
		splitContainer.AddChild(mRightPanel);

		splitContainer.SplitterPosition = mSplitterPosition;
		section.AddChild(splitContainer);

		mRoot.AddChild(section);
	}
}

/// A custom container that arranges children with a splitter.
class SplitterContainer : Panel
{
	public float SplitterPosition = 300;
	private float mSplitterThickness = 6;

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (ChildCount < 3)
		{
			base.ArrangeOverride(contentBounds);
			return;
		}

		let leftPanel = GetChild(0);
		let splitter = GetChild(1);
		let rightPanel = GetChild(2);

		// Left panel
		leftPanel?.Arrange(.(
			contentBounds.X,
			contentBounds.Y,
			SplitterPosition,
			contentBounds.Height
		));

		// Splitter
		splitter?.Arrange(.(
			contentBounds.X + SplitterPosition,
			contentBounds.Y,
			mSplitterThickness,
			contentBounds.Height
		));

		// Right panel
		let rightWidth = contentBounds.Width - SplitterPosition - mSplitterThickness;
		rightPanel?.Arrange(.(
			contentBounds.X + SplitterPosition + mSplitterThickness,
			contentBounds.Y,
			rightWidth,
			contentBounds.Height
		));
	}
}
