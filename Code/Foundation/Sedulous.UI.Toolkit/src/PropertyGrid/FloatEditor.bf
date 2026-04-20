using System;
namespace Sedulous.UI.Toolkit;

/// Float property editor - NumericField with focus-based edit transactions.
public class FloatEditor : PropertyEditor
{
	private double mValue;
	private NumericField mField;
	private double mMin;
	private double mMax;
	private double mStep;
	private int32 mDecimalPlaces;
	private double mPreEditValue;
	private bool mSyncing;

	public double Value
	{
		get => mValue;
		set { mValue = value; if (!mSyncing) RefreshView(); }
	}

	public delegate void(double) Setter ~ delete _;

	public this(StringView name, double initialValue, double min = -1e9, double max = 1e9,
		double step = 0.1, int32 decimalPlaces = 2, delegate void(double) setter = null,
		StringView category = default) : base(name, category)
	{
		mValue = initialValue;
		mMin = min; mMax = max; mStep = step; mDecimalPlaces = decimalPlaces;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		let field = new FloatEditorField(this);
		mField = field;
		mField.Min = mMin; mField.Max = mMax; mField.Step = mStep;
		mField.DecimalPlaces = mDecimalPlaces;
		mField.Value = mValue;
		mField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue = val; Setter?.Invoke(val); NotifyValueChanged(); mSyncing = false; }
		});
		return mField;
	}

	/// NumericField subclass that tracks edit transactions via focus.
	private class FloatEditorField : NumericField
	{
		private FloatEditor mEditor;

		public this(FloatEditor editor) { mEditor = editor; }

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
			if (e.Key == .Escape && mEditor.IsEditing)
			{
				mEditor.mValue = mEditor.mPreEditValue;
				Value = mEditor.mPreEditValue;
				mEditor.Setter?.Invoke(mEditor.mPreEditValue);
				mEditor.CancelEdit();
				e.Handled = true;
				return;
			}
			base.OnKeyDown(e);
		}
	}

	public override void RefreshView()
	{
		if (mField != null && !mSyncing) { mSyncing = true; mField.Value = mValue; mSyncing = false; }
	}
}
