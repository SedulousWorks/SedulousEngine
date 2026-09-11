using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// An enumeration: a combo box of names, with the INDEX as the value.
///
/// The index, not the enum itself, because the editor is not generic over the enum type; the
/// caller's setter maps the index back to whatever it means.
class EnumEditor : PropertyEditor
{
	/// OWNED.
	public delegate void(int32) Setter ~ delete _;

	private int32 mValue;
	private List<String> mItems = new .() ~ DeleteContainerAndItems!(_);
	/// BORROWED: the cached editor view owns it.
	private ComboBox mComboBox = null;
	private bool mSyncing = false;

	/// CONSUMES the setter. The item names are copied.
	public this(StringView name, int32 value, Span<StringView> items,
		delegate void(int32) setter = null, StringView category = default) : base(name, category)
	{
		Setter = setter;
		mValue = value;
		for (let item in items)
			mItems.Add(new String(item));
	}

	public int32 Value => mValue;

	public void SetValue(int32 value)
	{
		mValue = value;
		if (!mSyncing)
			RefreshView();
	}

	public override void RefreshView()
	{
		if ((mComboBox != null) && !mSyncing)
		{
			mSyncing = true;
			mComboBox.SetSelectedIndex(mValue);
			mSyncing = false;
		}
	}

	protected override View CreateEditorView()
	{
		mComboBox = new ComboBox();
		for (let item in mItems)
			mComboBox.AddItem(item);
		mComboBox.SetSelectedIndex(mValue);

		// The GUARD is what stops a refresh from being read back as a user edit: writing the
		// selection raises the same event a click does.
		mComboBox.OnSelectionChanged.Add(new (sender, index) =>
			{
				if (mSyncing)
					return;

				mSyncing = true;
				BeginEdit();
				mValue = index;
				if (Setter != null)
					Setter(mValue);
				NotifyValueChanged();
				EndEdit();
				mSyncing = false;
			});

		return mComboBox;
	}
}
