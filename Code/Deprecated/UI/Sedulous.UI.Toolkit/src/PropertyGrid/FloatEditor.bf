using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A real number: a numeric field, bounded by focus like [[StringEditor]].
class FloatEditor : PropertyEditor
{
	private class FocusReportingField : NumericField
	{
		private FloatEditor mEditor;

		public this(FloatEditor editor)
		{
			mEditor = editor;
		}

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			mEditor.mPreEditValue = mEditor.mValue;
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
				mEditor.mValue = mEditor.mPreEditValue;
				SetValue(mEditor.mPreEditValue);
				if (mEditor.Setter != null)
					mEditor.Setter(mEditor.mPreEditValue);
				mEditor.CancelEdit();
				e.Handled = true;
				return;
			}

			base.OnKeyDown(e);
		}
	}

	/// OWNED.
	public delegate void(double) Setter ~ delete _;

	private double mValue;
	private double mMin;
	private double mMax;
	private double mStep;
	private int32 mDecimalPlaces;
	private double mPreEditValue = 0.0;
	/// BORROWED: the cached editor view owns it.
	private NumericField mField = null;
	private bool mSyncing = false;

	/// CONSUMES the setter.
	public this(StringView name, double initialValue, double min = -1e9, double max = 1e9,
		double step = 0.1, int32 decimalPlaces = 2, delegate void(double) setter = null,
		StringView category = default) : base(name, category)
	{
		Setter = setter;
		mValue = initialValue;
		mMin = min;
		mMax = max;
		mStep = step;
		mDecimalPlaces = decimalPlaces;
	}

	public double Value => mValue;

	public void SetValue(double value)
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
			mField.SetValue(mValue);
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
		mField.SetStep(mStep);
		mField.SetDecimalPlaces(mDecimalPlaces);
		mField.SetValue(mValue);

		mField.OnValueChanged.Add(new (sender, value) =>
			{
				if (mSyncing)
					return;

				mSyncing = true;
				mValue = value;
				if (Setter != null)
					Setter(value);
				NotifyValueChanged();
				mSyncing = false;
			});

		return mField;
	}
}
