using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Fonts;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A numeric input control with up/down buttons.
public class NumericUpDown : Control
{
	// Value
	private double mValue = 0;
	private double mMinimum = double.MinValue;
	private double mMaximum = double.MaxValue;
	private double mStep = 1;
	private int32 mDecimalPlaces = 0;

	// Child controls
	private TextBox mTextBox = new .() ~ delete _;
	private RepeatButton mUpButton = new .("+") ~ delete _;
	private RepeatButton mDownButton = new .("-") ~ delete _;

	// Updating state
	private bool mIsUpdatingText = false;

	// Events
	private EventAccessor<delegate void(NumericUpDown, double)> mValueChanged = new .() ~ delete _;

	/// Creates a new NumericUpDown.
	public this()
	{
		// Parent child controls
		mTextBox.SetParent(this);
		mUpButton.SetParent(this);
		mDownButton.SetParent(this);

		// Configure text box
		mTextBox.TextChanged.Subscribe(new (tb, text) => {
			if (!mIsUpdatingText)
			{
				ParseTextValue();
			}
		});

		// Configure buttons
		mUpButton.Click.Subscribe(new (btn) => Increment());
		mDownButton.Click.Subscribe(new (btn) => Decrement());

		// Style buttons: no rounded corners, centered text, no padding
		mUpButton.CornerRadius = 0;
		mDownButton.CornerRadius = 0;
		mUpButton.Padding = .(0);
		mDownButton.Padding = .(0);

		// Center the text in buttons
		if (let upText = mUpButton.Content as TextBlock)
			upText.TextAlignment = .Center;
		if (let downText = mDownButton.Content as TextBlock)
			downText.TextAlignment = .Center;

		// Initialize text
		UpdateTextFromValue();
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "NumericUpDown";

	/// The current value.
	public double Value
	{
		get => mValue;
		set
		{
			let clamped = Math.Clamp(value, mMinimum, mMaximum);
			if (mValue != clamped)
			{
				mValue = clamped;
				UpdateTextFromValue();
				mValueChanged.[Friend]Invoke(this, mValue);
			}
		}
	}

	/// The minimum allowed value.
	public double Minimum
	{
		get => mMinimum;
		set
		{
			mMinimum = value;
			if (mValue < mMinimum)
				Value = mMinimum;
		}
	}

	/// The maximum allowed value.
	public double Maximum
	{
		get => mMaximum;
		set
		{
			mMaximum = value;
			if (mValue > mMaximum)
				Value = mMaximum;
		}
	}

	/// The step/increment amount for up/down buttons.
	public double Step
	{
		get => mStep;
		set => mStep = Math.Max(0, value);
	}

	/// Number of decimal places to display (0 for integers).
	public int32 DecimalPlaces
	{
		get => mDecimalPlaces;
		set
		{
			mDecimalPlaces = Math.Max(0, value);
			UpdateTextFromValue();
		}
	}

	/// Event fired when the value changes.
	public EventAccessor<delegate void(NumericUpDown, double)> ValueChanged => mValueChanged;

	/// Increments the value by Step.
	public void Increment()
	{
		Value = mValue + mStep;
	}

	/// Decrements the value by Step.
	public void Decrement()
	{
		Value = mValue - mStep;
	}

	// === Internal ===

	private void UpdateTextFromValue()
	{
		mIsUpdatingText = true;
		defer { mIsUpdatingText = false;}

		let text = scope String();
		if (mDecimalPlaces == 0)
		{
			text.AppendF("{}", (int64)Math.Round(mValue));
		}
		else
		{
			// Format with specified decimal places
			text.AppendF("{0:F}", mValue);
			// Trim to desired decimal places
			let dotIndex = text.IndexOf('.');
			if (dotIndex >= 0)
			{
				let desiredLen = dotIndex + 1 + mDecimalPlaces;
				if (text.Length > desiredLen)
					text.RemoveToEnd(desiredLen);
			}
		}
		mTextBox.Text = text;
	}

	private void ParseTextValue()
	{
		if (double.Parse(mTextBox.Text) case .Ok(let parsed))
		{
			// Don't use Value setter to avoid text loop
			let clamped = Math.Clamp(parsed, mMinimum, mMaximum);
			if (mValue != clamped)
			{
				mValue = clamped;
				mValueChanged.[Friend]Invoke(this, mValue);
			}
		}
	}

	// === Layout ===

	protected override Thickness GetEffectivePadding()
	{
		return .(0); // NumericUpDown manages internal layout
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Measure text box
		let textConstraints = SizeConstraints(0, 0, constraints.MaxWidth - 20, constraints.MaxHeight);
		mTextBox.Measure(textConstraints);

		// Buttons have fixed width
		let buttonWidth = 20.0f;
		let buttonHeight = mTextBox.DesiredSize.Height / 2;

		mUpButton.Measure(SizeConstraints.Exact(buttonWidth, buttonHeight));
		mDownButton.Measure(SizeConstraints.Exact(buttonWidth, buttonHeight));

		let totalWidth = mTextBox.DesiredSize.Width + buttonWidth;
		let totalHeight = mTextBox.DesiredSize.Height;

		return .(totalWidth, totalHeight);
	}

	protected override void ArrangeOverride(RectangleF finalRect)
	{
		base.ArrangeOverride(finalRect);

		let bounds = ContentBounds;
		let buttonWidth = 20.0f;
		let textWidth = bounds.Width - buttonWidth;
		let buttonHeight = bounds.Height / 2;

		// TextBox on left
		mTextBox.Arrange(RectangleF(bounds.X, bounds.Y, textWidth, bounds.Height));

		// Buttons stacked on right
		mUpButton.Arrange(RectangleF(bounds.X + textWidth, bounds.Y, buttonWidth, buttonHeight));
		mDownButton.Arrange(RectangleF(bounds.X + textWidth, bounds.Y + buttonHeight, buttonWidth, buttonHeight));
	}

	// === Rendering ===

	protected override void RenderOverride(DrawContext ctx)
	{
		// Draw background and border
		RenderBackground(ctx);

		// Children render themselves
		mTextBox.Render(ctx);
		mUpButton.Render(ctx);
		mDownButton.Render(ctx);
	}

	// === Input Handling ===

	protected override void OnKeyDown(KeyEventArgs e)
	{
		base.OnKeyDown(e);

		switch (e.Key)
		{
		case .Up:
			Increment();
			e.Handled = true;
		case .Down:
			Decrement();
			e.Handled = true;
		case .PageUp:
			Value = mValue + mStep * 10;
			e.Handled = true;
		case .PageDown:
			Value = mValue - mStep * 10;
			e.Handled = true;
		default:
		}
	}

	protected override void OnMouseWheel(MouseWheelEventArgs e)
	{
		base.OnMouseWheel(e);

		if (IsFocused || mTextBox.IsFocused)
		{
			if (e.DeltaY > 0)
				Increment();
			else if (e.DeltaY < 0)
				Decrement();
			e.Handled = true;
		}
	}

	// === Child Management ===

	public override void OnAttachedToContext(GUIContext context)
	{
		base.OnAttachedToContext(context);
		mTextBox.OnAttachedToContext(context);
		mUpButton.OnAttachedToContext(context);
		mDownButton.OnAttachedToContext(context);
	}

	public override void OnDetachedFromContext()
	{
		mTextBox.OnDetachedFromContext();
		mUpButton.OnDetachedFromContext();
		mDownButton.OnDetachedFromContext();
		base.OnDetachedFromContext();
	}

	public override int VisualChildCount => 3;

	public override UIElement GetVisualChild(int index)
	{
		switch (index)
		{
		case 0: return mTextBox;
		case 1: return mUpButton;
		case 2: return mDownButton;
		default: return null;
		}
	}

	// === Hit Testing ===

	public override UIElement HitTest(Sedulous.Core.Mathematics.Vector2 point)
	{
		if (Visibility != .Visible)
			return null;

		// Check if point is within our bounds
		if (!ArrangedBounds.Contains(point.X, point.Y))
			return null;

		// Check children in reverse order (front to back)
		// Children's ArrangedBounds are in same coordinate space (parent-relative)
		for (int i = VisualChildCount - 1; i >= 0; i--)
		{
			let child = GetVisualChild(i);
			if (child != null)
			{
				let hit = child.HitTest(point);
				if (hit != null)
					return hit;
			}
		}

		return this;
	}
}
