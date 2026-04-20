using System;
namespace Sedulous.UI.Toolkit;

/// Boolean property editor - CheckBox.
/// Instant edit: BeginEdit + value change + EndEdit on each toggle.
public class BoolEditor : PropertyEditor
{
	private bool mValue;
	private CheckBox mCheckBox;

	public bool Value
	{
		get => mValue;
		set { mValue = value; if (mCheckBox != null) mCheckBox.IsChecked = value; }
	}

	public delegate void(bool) Setter ~ delete _;

	public this(StringView name, bool initialValue, delegate void(bool) setter = null, StringView category = default)
		: base(name, category)
	{
		mValue = initialValue;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		mCheckBox = new CheckBox();
		mCheckBox.IsChecked = mValue;
		mCheckBox.OnCheckedChanged.Add(new (cb, val) => {
			BeginEdit();
			mValue = val;
			Setter?.Invoke(val);
			NotifyValueChanged();
			EndEdit();
		});
		return mCheckBox;
	}

	public override void RefreshView()
	{
		if (mCheckBox != null) mCheckBox.IsChecked = mValue;
	}
}
