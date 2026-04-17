namespace Sedulous.UI;

using System;

/// LinearLayout that manages mutual exclusion of RadioButton children.
/// When one RadioButton is checked, all others are unchecked.
public class RadioGroup : LinearLayout
{
	private RadioButton mCheckedButton;
	private bool mUpdating;

	public Event<delegate void(RadioGroup, RadioButton)> OnSelectionChanged ~ _.Dispose();

	/// The currently checked RadioButton, or null.
	public RadioButton CheckedButton => mCheckedButton;

	public this()
	{
		Orientation = .Vertical;
		Spacing = 4;
	}

	/// Add a RadioButton and subscribe to its checked events.
	public void AddRadioButton(RadioButton radio, LayoutParams lp = null)
	{
		AddView(radio, lp);
		radio.OnCheckedChanged.Add(new => OnRadioCheckedChanged);
	}

	private void OnRadioCheckedChanged(RadioButton button, bool isChecked)
	{
		if (mUpdating || !isChecked) return;

		mUpdating = true;

		// Uncheck all other RadioButtons.
		for (int i = 0; i < ChildCount; i++)
		{
			if (let radio = GetChildAt(i) as RadioButton)
			{
				if (radio !== button && radio.IsChecked)
					radio.IsChecked = false;
			}
		}

		mCheckedButton = button;
		mUpdating = false;

		OnSelectionChanged(this, button);
	}

	/// Programmatically select a RadioButton by index.
	public void CheckAt(int index)
	{
		if (let radio = GetChildAt(index) as RadioButton)
			radio.IsChecked = true;
	}

	/// Clear the selection.
	public void ClearCheck()
	{
		mUpdating = true;
		for (int i = 0; i < ChildCount; i++)
		{
			if (let radio = GetChildAt(i) as RadioButton)
				radio.IsChecked = false;
		}
		mCheckedButton = null;
		mUpdating = false;
	}
}
