namespace Sedulous.GUI;

using System;

/// Groups RadioButtons for mutual exclusion. Extends FlexLayout (vertical by default).
/// When one radio button is checked, all others are unchecked.
public class RadioGroup : FlexLayout
{
	private RadioButton mCheckedButton;
	private bool mUpdating; // guards against recursive update

	/// Fired when the selected radio button changes.
	public Event<delegate void(RadioGroup, RadioButton)> OnSelectionChanged ~ _.Dispose();

	/// The currently selected radio button.
	public RadioButton CheckedButton => mCheckedButton;

	public this()
	{
		Direction = .Vertical;
		Spacing = 4;
	}

	/// Add a radio button to the group.
	public void AddRadioButton(RadioButton radio)
	{
		AddView(radio);
		radio.OnCheckedChanged.Add(new (r, isChecked) => OnRadioCheckedChanged(r, isChecked));
	}

	/// Programmatically select a radio button by index.
	public void CheckAt(int index)
	{
		for (int i = 0; i < ChildCount; i++)
		{
			if (let radio = GetChildAt(i) as RadioButton)
			{
				if (i == index)
					radio.IsChecked.Value = true;
			}
		}
	}

	/// Clear selection (all unchecked).
	public void ClearCheck()
	{
		if (mUpdating) return;
		mUpdating = true;

		for (int i = 0; i < ChildCount; i++)
		{
			if (let radio = GetChildAt(i) as RadioButton)
				radio.IsChecked.Value = false;
		}
		mCheckedButton = null;

		mUpdating = false;
	}

	private void OnRadioCheckedChanged(RadioButton radio, bool isChecked)
	{
		if (mUpdating || !isChecked) return;
		mUpdating = true;

		// Uncheck all others
		for (int i = 0; i < ChildCount; i++)
		{
			if (let other = GetChildAt(i) as RadioButton)
			{
				if (other !== radio)
					other.IsChecked.Value = false;
			}
		}

		mCheckedButton = radio;
		mUpdating = false;

		OnSelectionChanged(this, radio);
	}
}
