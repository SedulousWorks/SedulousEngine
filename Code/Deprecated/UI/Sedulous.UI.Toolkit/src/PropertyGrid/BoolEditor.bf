using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A boolean property: a check box.
///
/// The edit is INSTANT, so a toggle opens and closes its transaction in one go and lands as a
/// single undo step rather than leaving one open waiting for a gesture that never comes.
class BoolEditor : PropertyEditor
{
	/// OWNED. Writes the value back to whatever is being edited.
	public delegate void(bool) Setter ~ delete _;

	private bool mValue;
	/// BORROWED: the cached editor view owns it.
	private CheckBox mCheckBox = null;

	/// CONSUMES the setter.
	public this(StringView name, bool initialValue, delegate void(bool) setter = null,
		StringView category = default) : base(name, category)
	{
		Setter = setter;
		mValue = initialValue;
	}

	public bool Value => mValue;

	public void SetValue(bool value)
	{
		mValue = value;
		if (mCheckBox != null)
			mCheckBox.IsChecked.Value = value;
	}

	public override void RefreshView()
	{
		if (mCheckBox != null)
			mCheckBox.IsChecked.Value = mValue;
	}

	protected override View CreateEditorView()
	{
		mCheckBox = new CheckBox();
		mCheckBox.IsChecked.Value = mValue;
		mCheckBox.OnCheckedChanged.Add(new (sender, value) =>
			{
				BeginEdit();
				mValue = value;
				if (Setter != null)
					Setter(value);
				NotifyValueChanged();
				EndEdit();
			});
		return mCheckBox;
	}
}
