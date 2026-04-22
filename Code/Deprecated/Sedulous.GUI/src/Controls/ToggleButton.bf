using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.Core;

namespace Sedulous.GUI;

/// A button that toggles between checked and unchecked states.
/// Base class for CheckBox and RadioButton.
public class ToggleButton : Button
{
	private bool mIsChecked = false;
	private bool? mIsThreeState = false; // null = indeterminate supported
	private EventAccessor<delegate void(ToggleButton, bool)> mChecked = new .() ~ delete _;
	private EventAccessor<delegate void(ToggleButton)> mUnchecked = new .() ~ delete _;

	/// Event raised when IsChecked changes.
	public EventAccessor<delegate void(ToggleButton, bool)> Checked => mChecked;

	/// Event raised when IsChecked becomes false.
	public EventAccessor<delegate void(ToggleButton)> Unchecked => mUnchecked;

	/// Creates a new ToggleButton.
	public this() : base()
	{
	}

	/// Creates a new ToggleButton with text content.
	public this(StringView text) : base(text)
	{
	}

	/// The control type name for theming.
	protected override StringView ControlTypeName => "ToggleButton";

	/// Whether the button is checked.
	public bool IsChecked
	{
		get => mIsChecked;
		set
		{
			if (mIsChecked != value)
			{
				mIsChecked = value;
				OnIsCheckedChanged();
			}
		}
	}

	/// Whether the button supports three states (checked, unchecked, indeterminate).
	/// Only meaningful for CheckBox.
	public bool IsThreeState
	{
		get => mIsThreeState.HasValue && mIsThreeState.Value;
		set => mIsThreeState = value;
	}

	/// Called when IsChecked changes.
	protected virtual void OnIsCheckedChanged()
	{
		// Always fire Checked with the new state
		mChecked.[Friend]Invoke(this, mIsChecked);

		// Also fire Unchecked for backwards compatibility when becoming unchecked
		if (!mIsChecked)
			mUnchecked.[Friend]Invoke(this);
	}

	/// Called when the button is clicked.
	protected override void OnClick()
	{
		// Toggle the checked state
		IsChecked = !mIsChecked;

		// Call base to execute command and raise Click event
		base.OnClick();
	}

	/// Gets the background color for the current state.
	protected override Color GetStateBackground()
	{
		let baseColor = mIsChecked ? GetCheckedBackground() : Background;
		switch (CurrentState)
		{
		case .Disabled:
			return Palette.ComputeDisabled(baseColor);
		case .Pressed:
			return Palette.ComputePressed(baseColor);
		case .Hover:
			return Palette.ComputeHover(baseColor);
		case .Focused:
			return baseColor;
		default:
			return baseColor;
		}
	}

	/// Gets the background color when checked.
	protected virtual Color GetCheckedBackground()
	{
		// Use accent color for checked state
		if (let theme = Context?.Theme)
			return theme.Palette.Accent;
		return Color(100, 149, 237, 255); // Fallback: cornflower blue
	}

	/// Renders the button with checked state indication.
	protected override void RenderOverride(DrawContext ctx)
	{
		// Let base class handle normal button rendering
		// Subclasses (CheckBox, RadioButton) override for custom appearance
		base.RenderOverride(ctx);
	}
}
