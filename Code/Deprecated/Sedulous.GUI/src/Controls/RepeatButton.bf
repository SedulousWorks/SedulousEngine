using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// A button that fires repeatedly while pressed.
/// Useful for increment/decrement buttons or scroll arrows.
public class RepeatButton : Button
{
	private float mDelay = 0.5f; // Initial delay in seconds before repeating starts
	private float mInterval = 0.1f; // Interval in seconds between repeats
	private double mLastClickTime = 0;
	private bool mIsRepeating = false;
	private bool mKeyPressed = false;

	/// Creates a new RepeatButton.
	public this() : base()
	{
	}

	/// Creates a new RepeatButton with text content.
	public this(StringView text) : base(text)
	{
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "RepeatButton";

	/// Initial delay in seconds before repeating starts (default 0.5).
	public float Delay
	{
		get => mDelay;
		set => mDelay = Math.Max(0, value);
	}

	/// Interval in seconds between repeats (default 0.1).
	public float Interval
	{
		get => mInterval;
		set => mInterval = Math.Max(0.01f, value); // Minimum 10ms to prevent runaway
	}

	/// Handles mouse button press.
	protected override void OnMouseDown(MouseButtonEventArgs e)
	{
		if (e.Button == .Left && IsEnabled)
		{
			IsPressed = true;
			e.Handled = true;

			// Capture mouse to track release
			Context?.FocusManager?.SetCapture(this);

			// Fire first click immediately
			OnClick();

			// Start repeat timer
			mLastClickTime = Context?.TotalTime ?? 0;
			mIsRepeating = false;
		}
	}

	/// Handles mouse button release.
	protected override void OnMouseUp(MouseButtonEventArgs e)
	{
		if (e.Button == .Left && IsPressed)
		{
			IsPressed = false;
			e.Handled = true;
			mIsRepeating = false;

			// Release capture
			Context?.FocusManager?.ReleaseCapture();
		}
	}

	/// Renders the button and handles repeat timing.
	protected override void RenderOverride(DrawContext ctx)
	{
		// Handle repeat timing during render (called every frame)
		if ((IsPressed || mKeyPressed) && IsEnabled && (IsHovered || mKeyPressed))
		{
			let currentTime = Context?.TotalTime ?? 0;
			let elapsed = currentTime - mLastClickTime;

			if (!mIsRepeating)
			{
				// Waiting for initial delay
				if (elapsed >= mDelay)
				{
					mIsRepeating = true;
					mLastClickTime = currentTime;
					OnClick();
				}
			}
			else
			{
				// Repeating at interval
				if (elapsed >= mInterval)
				{
					mLastClickTime = currentTime;
					OnClick();
				}
			}
		}

		// Render the button visuals
		base.RenderOverride(ctx);
	}

	/// Handles key press.
	protected override void OnKeyDown(KeyEventArgs e)
	{
		if (!IsEnabled)
			return;

		// Space or Enter activates the button
		if (e.Key == .Space || e.Key == .Return)
		{
			if (!mKeyPressed)
			{
				mKeyPressed = true;
				IsPressed = true;
				e.Handled = true;

				// Fire first click immediately
				OnClick();

				// Start repeat timer
				mLastClickTime = Context?.TotalTime ?? 0;
				mIsRepeating = false;
			}
		}
	}

	/// Handles key release.
	protected override void OnKeyUp(KeyEventArgs e)
	{
		if (!IsEnabled)
			return;

		if ((e.Key == .Space || e.Key == .Return) && mKeyPressed)
		{
			mKeyPressed = false;
			IsPressed = false;
			mIsRepeating = false;
			e.Handled = true;
		}
	}
}
