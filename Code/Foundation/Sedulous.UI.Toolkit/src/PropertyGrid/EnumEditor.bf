namespace Sedulous.UI.Toolkit;

using System;
using System.Collections;
using Sedulous.UI;

/// Property editor for enumeration values. Uses a ComboBox with string items.
public class EnumEditor : PropertyEditor
{
	private int32 mValue;
	private List<String> mItems = new .() ~ { for (var s in _) delete s; delete _; };
	private ComboBox mComboBox;
	private bool mSyncing;

	public int32 Value
	{
		get => mValue;
		set
		{
			mValue = value;
			if (!mSyncing) RefreshView();
		}
	}

	public delegate void(int32) Setter ~ delete _;

	public this(StringView name, int32 value, Span<StringView> items,
		delegate void(int32) setter = null, StringView category = default)
		: base(name, category)
	{
		mValue = value;
		Setter = setter;
		for (let item in items)
			mItems.Add(new String(item));
	}

	protected override View CreateEditorView()
	{
		mComboBox = new ComboBox();
		for (let item in mItems)
			mComboBox.AddItem(item);
		mComboBox.SelectedIndex = mValue;
		mComboBox.OnSelectionChanged.Add(new (cb, idx) =>
		{
			if (!mSyncing)
			{
				mSyncing = true;
				BeginEdit();
				mValue = (int32)idx;
				Setter?.Invoke(mValue);
				NotifyValueChanged();
				EndEdit();
				mSyncing = false;
			}
		});
		return mComboBox;
	}

	public override void RefreshView()
	{
		if (mComboBox != null && !mSyncing)
		{
			mSyncing = true;
			mComboBox.SelectedIndex = mValue;
			mSyncing = false;
		}
	}
}
