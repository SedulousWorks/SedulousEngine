using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A radio button control for mutually exclusive selections.
/// RadioButtons with the same GroupName are mutually exclusive.
public class RadioButton : ToggleButton
{
	private String mGroupName ~ delete _;
	private float mCircleSize = 18;
	private float mCircleSpacing = 8;
	private ImageBrush? mUnselectedImage;
	private ImageBrush? mSelectedImage;

	/// Creates a new RadioButton.
	public this() : base()
	{
	}

	/// Creates a new RadioButton with text content.
	public this(StringView text) : base()
	{
		// Create TextBlock with left alignment (not center like Button)
		let textBlock = new TextBlock(text);
		textBlock.TextAlignment = .Left;
		textBlock.VerticalAlignment = .Center;
		Content = textBlock;
	}

	/// Creates a new RadioButton with text and group name.
	public this(StringView text, StringView groupName) : this(text)
	{
		GroupName = groupName;
	}

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		ApplyThemeDefaults();
	}

	/// Applies theme defaults for radio button dimensions.
	private void ApplyThemeDefaults()
	{
		let theme = Context?.Theme;
		mCircleSize = theme?.RadioButtonSize ?? 18;
		mCircleSpacing = theme?.RadioButtonSpacing ?? 8;
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "RadioButton";

	/// The group name for mutual exclusion.
	/// RadioButtons with the same GroupName in the same visual tree are mutually exclusive.
	public StringView GroupName
	{
		get => mGroupName ?? "";
		set
		{
			if (mGroupName == null)
				mGroupName = new String(value);
			else
				mGroupName.Set(value);
		}
	}

	/// The size of the radio circle indicator (default 18).
	public float CircleSize
	{
		get => mCircleSize;
		set => mCircleSize = Math.Max(12, value);
	}

	/// The spacing between the radio circle and content (default 8).
	public float CircleSpacing
	{
		get => mCircleSpacing;
		set => mCircleSpacing = Math.Max(0, value);
	}

	/// Image for the unselected radio indicator.
	public ImageBrush? UnselectedImage
	{
		get => mUnselectedImage;
		set => mUnselectedImage = value;
	}

	/// Image for the selected radio indicator (includes inner dot in the texture).
	public ImageBrush? SelectedImage
	{
		get => mSelectedImage;
		set => mSelectedImage = value;
	}

	/// Called when the button is clicked.
	protected override void OnClick()
	{
		// RadioButton only becomes checked, never unchecked by clicking
		if (!IsChecked)
		{
			// Uncheck other radio buttons in the same group
			UncheckOthersInGroup();
			IsChecked = true;
		}

		// Execute command if bound (skip toggle behavior of ToggleButton)
		if (Command != null && Command.CanExecute(CommandParameter))
			Command.Execute(CommandParameter);

		// Raise click event using helper from Button
		RaiseClick();
	}

	/// Unchecks all other RadioButtons in the same group.
	private void UncheckOthersInGroup()
	{
		if (mGroupName == null || mGroupName.IsEmpty)
			return;

		// Find parent container to search siblings
		let parent = Parent;
		if (parent == null)
			return;

		// Iterate through siblings
		let childCount = parent.VisualChildCount;
		for (int i = 0; i < childCount; i++)
		{
			let child = parent.GetVisualChild(i);
			if (child == this)
				continue;

			if (let radio = child as RadioButton)
			{
				if (radio.GroupName == mGroupName)
					radio.IsChecked = false;
			}
		}
	}

	/// Measures the radio button with its indicator and content.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure content
		DesiredSize contentSize = .Zero;
		if (Content != null)
		{
			let contentConstraints = constraints.Deflate(Thickness(mCircleSize + mCircleSpacing, 0));
			contentSize = Content.Measure(contentConstraints);
		}

		// Total size: circle + spacing + content
		return DesiredSize(
			mCircleSize + mCircleSpacing + contentSize.Width,
			Math.Max(mCircleSize, contentSize.Height)
		);
	}

	/// Arranges the radio button content.
	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		if (Content != null)
		{
			// Content goes to the right of the radio circle
			let contentX = contentBounds.X + mCircleSize + mCircleSpacing;
			let contentWidth = contentBounds.Width - mCircleSize - mCircleSpacing;
			let contentBoundsAdjusted = RectangleF(
				contentX,
				contentBounds.Y,
				contentWidth,
				contentBounds.Height
			);
			Content.Arrange(contentBoundsAdjusted);
		}
	}

	/// Renders the radio button with its indicator and content.
	protected override void RenderOverride(DrawContext ctx)
	{
		let bounds = ArrangedBounds;
		let style = GetThemeStyle();

		// Calculate radio circle position (vertically centered)
		let circleY = bounds.Y + (bounds.Height - mCircleSize) / 2;
		let circleRect = RectangleF(bounds.X, circleY, mCircleSize, mCircleSize);
		let centerX = circleRect.X + mCircleSize / 2;
		let centerY = circleRect.Y + mCircleSize / 2;
		let outerRadius = mCircleSize / 2;

		// Try image-based indicator first
		ImageBrush? indicatorImage = IsChecked ? mSelectedImage : mUnselectedImage;
		if (indicatorImage.HasValue && indicatorImage.Value.IsValid)
		{
			var img = indicatorImage.Value;
			img.Tint = ControlStyle.ModulateTint(img.Tint, CurrentState);
			ctx.DrawImageBrush(img, circleRect);
		}
		else
		{
			// Get colors based on state
			let bgColor = GetStateBackground();
			let borderColor = GetStateBorderColor();

			// Draw outer circle background
			if (bgColor.A > 0)
			{
				ctx.FillCircle(.(centerX, centerY), outerRadius, bgColor);
			}

			// Draw outer circle border
			if (style.BorderThickness > 0 && borderColor.A > 0)
			{
				ctx.DrawCircle(.(centerX, centerY), outerRadius - style.BorderThickness / 2, borderColor, style.BorderThickness);
			}

			// Draw inner dot if checked
			if (IsChecked)
			{
				let dotColor = GetCheckedBackground();
				let innerRadius = outerRadius * 0.45f;
				ctx.FillCircle(.(centerX, centerY), innerRadius, dotColor);
			}
		}

		// Draw content (label text)
		Content?.Render(ctx);

		// Draw focus indicator around radio circle
		if (IsFocused)
		{
			let focusColor = FocusBorderColor;
			let focusThickness = FocusBorderThickness;
			ctx.DrawCircle(.(centerX, centerY), outerRadius + focusThickness, focusColor, focusThickness);
		}
	}

	/// Gets the background color for the radio circle.
	protected override Color GetStateBackground()
	{
		// Use surface color for background
		if (let theme = Context?.Theme)
			return theme.Palette.Surface;
		return Color(255, 255, 255, 255); // Fallback white
	}
}
