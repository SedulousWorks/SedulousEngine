using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A set of radio buttons, exactly one of which is checked.
///
/// A vertical flex layout that also wires the mutual exclusion: a radio button only ever checks
/// itself, so something has to uncheck the rest, and this is it.
class RadioGroup : FlexLayout
{
	public Event<delegate void(RadioGroup, RadioButton)> OnSelectionChanged ~ _.Dispose();

	private RadioButton mCheckedButton = null;
	/// Guards the cascade: unchecking the siblings fires their Changed handlers, which land
	/// back here. Without it the first selection recurses through the whole group.
	private bool mUpdating = false;

	public this()
	{
		Direction = .Vertical;
		Spacing = 4.0f;
	}

	/// Borrowed; null when nothing is selected.
	public RadioButton CheckedButton => mCheckedButton;

	/// Adds a button and wires it into the exclusion. CONSUMES the caller's reference, as
	/// AddView does.
	public void AddRadioButton(RadioButton radio)
	{
		AddView(radio);
		radio.OnCheckedChanged.Add(new (r, isChecked) => { OnRadioCheckedChanged(r, isChecked); });
	}

	/// Selects by position. Out of range selects nothing.
	public void CheckAt(int index)
	{
		for (int i < ChildCount)
		{
			if (let radio = GetChildAt(i) as RadioButton)
			{
				if (i == index)
					radio.IsChecked.Value = true;
			}
		}
	}

	/// Leaves nothing selected.
	public void ClearCheck()
	{
		if (mUpdating)
			return;

		mUpdating = true;
		for (int i < ChildCount)
		{
			if (let radio = GetChildAt(i) as RadioButton)
				radio.IsChecked.Value = false;
		}
		mCheckedButton = null;
		mUpdating = false;
	}

	private void OnRadioCheckedChanged(RadioButton radio, bool isChecked)
	{
		// Only a CHECK drives the group. An uncheck is either one this method just did, or the
		// caller clearing a button directly, and neither should pick a new selection.
		if (mUpdating || !isChecked)
			return;

		mUpdating = true;
		for (int i < ChildCount)
		{
			if (let other = GetChildAt(i) as RadioButton)
			{
				if (other != radio)
					other.IsChecked.Value = false;
			}
		}
		mCheckedButton = radio;
		mUpdating = false;

		// Fired AFTER the guard is dropped, so a handler is free to change the selection again.
		OnSelectionChanged(this, radio);
	}
}
