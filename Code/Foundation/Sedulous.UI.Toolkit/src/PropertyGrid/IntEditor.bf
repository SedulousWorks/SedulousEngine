using System;
namespace Sedulous.UI.Toolkit;

/// Integer property editor - NumericField with 0 decimal places.
public class IntEditor : PropertyEditor
{
	private int64 mValue;
	private NumericField mField;
	private double mMin;
	private double mMax;
	private double mPreEditValue;
	private bool mSyncing;

	public int64 Value
	{
		get => mValue;
		set { mValue = value; if (!mSyncing) RefreshView(); }
	}

	public delegate void(int64) Setter ~ delete _;

	public this(StringView name, int64 initialValue, int64 min = int64.MinValue, int64 max = int64.MaxValue,
		delegate void(int64) setter = null, StringView category = default) : base(name, category)
	{
		mValue = initialValue;
		mMin = (double)min; mMax = (double)max;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		let field = new IntEditorField(this);
		mField = field;
		mField.Min = mMin; mField.Max = mMax; mField.Step = 1;
		mField.DecimalPlaces = 0;
		mField.Value = (double)mValue;
		mField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue = (int64)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		return mField;
	}

	/// NumericField subclass that tracks edit transactions via focus.
	private class IntEditorField : NumericField
	{
		private IntEditor mEditor;

		public this(IntEditor editor) { mEditor = editor; }

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
			if (e.Key == .Escape && mEditor.IsEditing)
			{
				mEditor.mValue = (int64)mEditor.mPreEditValue;
				Value = mEditor.mPreEditValue;
				mEditor.Setter?.Invoke(mEditor.mValue);
				mEditor.CancelEdit();
				e.Handled = true;
				return;
			}
			base.OnKeyDown(e);
		}
	}

	public override void RefreshView()
	{
		if (mField != null && !mSyncing) { mSyncing = true; mField.Value = (double)mValue; mSyncing = false; }
	}
}
