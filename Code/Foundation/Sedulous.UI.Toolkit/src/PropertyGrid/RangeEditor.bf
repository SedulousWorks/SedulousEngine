namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Range/slider property editor - Slider + NumericField.
/// Edit transactions tracked via slider drag events and numeric field focus.
public class RangeEditor : PropertyEditor
{
	private float mValue;
	private Slider mSlider;
	private float mMin;
	private float mMax;
	private float mStep;

	public float Value
	{
		get => mValue;
		set { mValue = value; if (mSlider != null) mSlider.Value = value; }
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
		mSlider = new Slider();
		mSlider.Min = mMin; mSlider.Max = mMax; mSlider.Step = mStep;
		mSlider.Value = mValue;
		mSlider.OnDragStarted.Add(new (s) => BeginEdit());
		mSlider.OnValueChanged.Add(new (s, val) => {
			mValue = val;
			Setter?.Invoke(val);
			NotifyValueChanged();
		});
		mSlider.OnDragEnded.Add(new (s) => EndEdit());
		return mSlider;
	}

	public override void RefreshView()
	{
		if (mSlider != null) mSlider.Value = mValue;
	}
}
