namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Particles;

/// Property editor for RangeFloat (Min/Max float pair). Two NumericFields
/// side-by-side. Edits write back through the field pointer captured at
/// construction. Both fields share a single edit transaction so dirty
/// tracking + sim restart see one Begin/End cycle per gesture.
class RangeFloatEditor : PropertyEditor
{
	private RangeFloat* mPtr;
	private float mMin;
	private float mMax;
	private NumericField mMinField;
	private NumericField mMaxField;
	private bool mSyncing;

	public this(StringView name, RangeFloat* ptr, float min = -1e6f, float max = 1e6f,
		StringView category = default) : base(name, category)
	{
		mPtr = ptr;
		mMin = min;
		mMax = max;
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		mMinField = new RangeNumericField(this);
		mMinField.ShowSpinButtons.Value = false;
		mMinField.Min = mMin; mMinField.Max = mMax; mMinField.Step = 0.1;
		mMinField.DecimalPlaces = 3;
		mMinField.Value = mPtr.Min;
		mMinField.SetPrefix("Min");
		mMinField.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.Min = (float)val;
			NotifyValueChanged();
			mSyncing = false;
		});
		row.AddView(mMinField, new FlexLayout.LayoutParams() { Grow = 1 });

		mMaxField = new RangeNumericField(this);
		mMaxField.ShowSpinButtons.Value = false;
		mMaxField.Min = mMin; mMaxField.Max = mMax; mMaxField.Step = 0.1;
		mMaxField.DecimalPlaces = 3;
		mMaxField.Value = mPtr.Max;
		mMaxField.SetPrefix("Max");
		mMaxField.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.Max = (float)val;
			NotifyValueChanged();
			mSyncing = false;
		});
		row.AddView(mMaxField, new FlexLayout.LayoutParams() { Grow = 1 });

		return row;
	}

	private class RangeNumericField : NumericField
	{
		private RangeFloatEditor mEditor;
		public this(RangeFloatEditor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			if (!mEditor.IsEditing) mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			// EndEdit only if neither sibling field still has focus.
			if (mEditor.IsEditing &&
				(mEditor.mMinField == null || !mEditor.mMinField.IsFocused) &&
				(mEditor.mMaxField == null || !mEditor.mMaxField.IsFocused))
				mEditor.EndEdit();
		}
	}

	public override void RefreshView()
	{
		if (mMinField == null || mSyncing) return;
		mSyncing = true;
		mMinField.Value = mPtr.Min;
		mMaxField.Value = mPtr.Max;
		mSyncing = false;
	}
}
