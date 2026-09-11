using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A whole number: a numeric field with no decimal places, bounded by focus like [[StringEditor]].
class IntEditor : PropertyEditor
{
	private class FocusReportingField : NumericField
	{
		private IntEditor mEditor;

		public this(IntEditor editor)
		{
			mEditor = editor;
		}

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			mEditor.mPreEditValue = (double)mEditor.mValue;
			mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing)
				mEditor.EndEdit();
		}

		public override void OnKeyDown(KeyEventArgs e)
		{
			if ((e.Key == .Escape) && mEditor.IsEditing)
			{
				mEditor.mValue = (int64)mEditor.mPreEditValue;
				SetValue(mEditor.mPreEditValue);
				if (mEditor.Setter != null)
					mEditor.Setter(mEditor.mValue);
				mEditor.CancelEdit();
				e.Handled = true;
				return;
			}

			base.OnKeyDown(e);
		}
	}

	/// OWNED.
	public delegate void(int64) Setter ~ delete _;

	private int64 mValue;
	private double mMin;
	private double mMax;
	private double mPreEditValue = 0.0;
	/// BORROWED: the cached editor view owns it.
	private NumericField mField = null;
	private bool mSyncing = false;

	/// CONSUMES the setter.
	public this(StringView name, int64 initialValue, int64 min = int64.MinValue,
		int64 max = int64.MaxValue, delegate void(int64) setter = null,
		StringView category = default) : base(name, category)
	{
		Setter = setter;
		mValue = initialValue;
		mMin = (double)min;
		mMax = (double)max;
	}

	public int64 Value => mValue;

	public void SetValue(int64 value)
	{
		mValue = value;
		if (!mSyncing)
			RefreshView();
	}

	public override void RefreshView()
	{
		if ((mField != null) && !mSyncing)
		{
			mSyncing = true;
			mField.SetValue((double)mValue);
			mSyncing = false;
		}
	}

	protected override View CreateEditorView()
	{
		let field = new FocusReportingField(this);
		field.AddClass("property-field");
		mField = field;
		mField.SetMin(mMin);
		mField.SetMax(mMax);
		mField.SetStep(1);
		mField.SetDecimalPlaces(0);
		mField.SetValue((double)mValue);

		mField.OnValueChanged.Add(new [=](sender, value) =>
			{
				if (mSyncing)
					return;

				mSyncing = true;
				mValue = (int64)value;
				if (Setter != null)
					Setter(mValue);
				NotifyValueChanged();
				mSyncing = false;
			});

		return mField;
	}
}
