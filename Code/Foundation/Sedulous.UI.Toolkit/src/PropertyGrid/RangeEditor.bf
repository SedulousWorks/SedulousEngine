using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A bounded number shown BOTH ways: a slider for feel and a numeric field for precision, kept
/// in step with one another.
///
/// The slider's own drag start and end bound the transaction; the field falls back to focus.
/// One guard covers both, so writing one control from the other is never read back as a second
/// edit.
class RangeEditor : PropertyEditor
{
	private class FocusReportingField : NumericField
	{
		private RangeEditor mEditor;

		public this(RangeEditor editor)
		{
			mEditor = editor;
		}

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing)
				mEditor.EndEdit();
		}
	}

	/// OWNED.
	public delegate void(float) Setter ~ delete _;

	private float mValue;
	private float mMin;
	private float mMax;
	private float mStep;
	/// BORROWED: the row tree owns both.
	private Slider mSlider = null;
	private NumericField mNumericField = null;
	private bool mSyncing = false;

	/// CONSUMES the setter. A step of zero means continuous.
	public this(StringView name, float initialValue, float min = 0.0f, float max = 1.0f,
		float step = 0.0f, delegate void(float) setter = null, StringView category = default)
		: base(name, category)
	{
		Setter = setter;
		mValue = initialValue;
		mMin = min;
		mMax = max;
		mStep = step;
	}

	public float Value => mValue;

	public void SetValue(float value)
	{
		mValue = value;
		if (!mSyncing)
			RefreshView();
	}

	public override void RefreshView()
	{
		if (mSyncing)
			return;

		mSyncing = true;
		if (mSlider != null)
			mSlider.Value.Value = mValue;
		if (mNumericField != null)
			mNumericField.SetValue(mValue);
		mSyncing = false;
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4.0f;

		mSlider = new Slider();
		mSlider.Min.Value = mMin;
		mSlider.Max.Value = mMax;
		mSlider.Step.Value = mStep;
		mSlider.Value.Value = mValue;

		// The DRAG bounds the transaction, so a sweep across the whole range is one undo step.
		mSlider.OnDragStarted.Add(new [=](sender) => { BeginEdit(); });
		mSlider.OnDragEnded.Add(new [=](sender) => { EndEdit(); });
		mSlider.OnValueChanged.Add(new [=](sender, value) =>
			{
				if (mSyncing)
					return;

				mSyncing = true;
				mValue = value;
				if (mNumericField != null)
					mNumericField.SetValue(value);
				if (Setter != null)
					Setter(value);
				NotifyValueChanged();
				mSyncing = false;
			});

		LayoutStyle sliderStyle = .();
		sliderStyle.Width = SizeSpec.Wrap();
		sliderStyle.Height = SizeSpec.Match();
		sliderStyle.FlexGrow = 1.0f;
		row.AddView(mSlider, sliderStyle);

		let field = new FocusReportingField(this);
		field.AddClass("property-field");
		mNumericField = field;
		mNumericField.SetMin(mMin);
		mNumericField.SetMax(mMax);
		// A continuous range still needs a keyboard step, so zero becomes a tenth here.
		mNumericField.SetStep((mStep > 0.0f) ? mStep : 0.1);
		mNumericField.SetDecimalPlaces(2);
		mNumericField.SetValue(mValue);
		mNumericField.OnValueChanged.Add(new [=](sender, value) =>
			{
				if (mSyncing)
					return;

				mSyncing = true;
				mValue = (float)value;
				if (mSlider != null)
					mSlider.Value.Value = mValue;
				if (Setter != null)
					Setter(mValue);
				NotifyValueChanged();
				mSyncing = false;
			});

		LayoutStyle fieldStyle = .();
		fieldStyle.Width = SizeSpec.Fixed(Unit.Dp(ComputeNumericFieldWidth()));
		fieldStyle.Height = SizeSpec.Match();
		row.AddView(mNumericField, fieldStyle);

		return row;
	}

	/// The WORST CASE rendered width of the readout, so the field never resizes as the number
	/// changes and the slider beside it never shifts under the pointer mid drag.
	///
	/// The longer of the two ends decides the digit count; a range that reaches below zero buys
	/// one more character for the sign.
	///
	/// The digits are COUNTED rather than taken from a base ten logarithm, which is what the
	/// C++ does: at an exact power of ten the log lands a hair under the integer and truncates
	/// to one digit too few, so a range ending at 1000 would size its field for 999.
	private float ComputeNumericFieldWidth()
	{
		let absMax = Max(Abs(mMin), Abs(mMax));
		var integerDigits = 1;
		var remaining = absMax;
		while (remaining >= 10.0f)
		{
			remaining /= 10.0f;
			integerDigits++;
		}

		var chars = integerDigits + 1 + 2; // digits, the point, two decimals
		if (mMin < 0.0f)
			chars++;

		chars = Min(chars, 6);
		return Max(60.0f, ((float)chars * 12.0f) + 16.0f);
	}
}
