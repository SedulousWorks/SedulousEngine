namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Range/slider property editor - Slider + NumericField side by side.
/// Slider for visual tweaking, NumericField for precise input. Both synced.
public class RangeEditor : PropertyEditor
{
	private float mValue;
	private Slider mSlider;
	private NumericField mNumericField;
	private float mMin;
	private float mMax;
	private float mStep;
	private bool mSyncing;

	public float Value
	{
		get => mValue;
		set { mValue = value; if (!mSyncing) RefreshView(); }
	}

	public delegate void(float) Setter ~ delete _;

	public this(StringView name, float initialValue, float min = 0, float max = 1,
		float step = 0, delegate void(float) setter = null,
		StringView category = default) : base(name, category)
	{
		mValue = initialValue;
		mMin = min; mMax = max; mStep = step;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		// Slider (fills available space)
		mSlider = new Slider();
		mSlider.Min.Value = mMin; mSlider.Max.Value = mMax; mSlider.Step.Value = mStep;
		mSlider.Value.Value = mValue;
		mSlider.OnDragStarted.Add(new (s) => BeginEdit());
		mSlider.OnValueChanged.Add(new (s, val) => {
			if (!mSyncing)
			{
				mSyncing = true;
				mValue = val;
				if (mNumericField != null)
					mNumericField.Value = val;
				Setter?.Invoke(val);
				NotifyValueChanged();
				mSyncing = false;
			}
		});
		mSlider.OnDragEnded.Add(new (s) => EndEdit());
		row.AddView(mSlider, new FlexLayout.LayoutParams() {
			Width = .Wrap, Height = .Match, Grow = 1
		});

		// NumericField (fixed width for precise input). Width is computed
		// from the range so values like "11.00" don't clip while values
		// like "1.00" don't waste space; range like 0..200 still fits
		// without a manual sentinel.
		mNumericField = new RangeNumericField(this);
		mNumericField.Min = mMin; mNumericField.Max = mMax;
		mNumericField.Step = (mStep > 0) ? mStep : 0.1;
		mNumericField.DecimalPlaces = 2;
		mNumericField.Value = mValue;
		mNumericField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing)
			{
				mSyncing = true;
				mValue = (float)val;
				if (mSlider != null)
					mSlider.Value.Value = (float)val;
				Setter?.Invoke((float)val);
				NotifyValueChanged();
				mSyncing = false;
			}
		});
		row.AddView(mNumericField, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(ComputeNumericFieldWidth())), Height = .Match
		});

		return row;
	}

	/// NumericField subclass that tracks edit transactions via focus.
	private class RangeNumericField : NumericField
	{
		private RangeEditor mEditor;

		public this(RangeEditor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			if (!mEditor.IsEditing)
				mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing)
				mEditor.EndEdit();
		}
	}

	/// Worst-case rendered width for the numeric readout. Picks the longer
	/// of |Min| and Max, computes integer digits + dot + decimal places,
	/// adds a sign slot if the range can go negative, plus padding. The
	/// original fixed 60 px clipped 5 chars ("11.00"), so an inspector
	/// glyph runs ~12 px wide; 12 px per char + 16 px padding.
	///
	/// Capped at 6 chars (88 px). Wider ranges like [0, 10000] would
	/// blow out the readout to 112 px even though the actual value is
	/// almost always within 3-4 digits. Rare extreme values can clip in
	/// the readout - the slider still drives the value.
	private float ComputeNumericFieldWidth()
	{
		let absMax = (float)Math.Max(Math.Abs(mMin), Math.Abs(mMax));
		int32 intDigits = (absMax >= 1) ? (int32)Math.Log10(absMax) + 1 : 1;
		int32 chars = intDigits + 1 + 2; // int + dot + 2 decimals
		if (mMin < 0) chars++; // negative sign
		chars = Math.Min(chars, 6);
		return Math.Max(60, chars * 12 + 16);
	}

	public override void RefreshView()
	{
		if (!mSyncing)
		{
			mSyncing = true;
			if (mSlider != null) mSlider.Value.Value = mValue;
			if (mNumericField != null) mNumericField.Value = mValue;
			mSyncing = false;
		}
	}
}
