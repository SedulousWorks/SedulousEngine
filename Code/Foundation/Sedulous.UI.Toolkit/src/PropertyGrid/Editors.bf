namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Boolean property editor - CheckBox.
public class BoolEditor : PropertyEditor
{
	private bool mValue;
	private CheckBox mCheckBox;

	public bool Value
	{
		get => mValue;
		set { mValue = value; if (mCheckBox != null) mCheckBox.IsChecked = value; }
	}

	public delegate void(bool) Setter ~ delete _;

	public this(StringView name, bool initialValue, delegate void(bool) setter = null, StringView category = default)
		: base(name, category)
	{
		mValue = initialValue;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		mCheckBox = new CheckBox();
		mCheckBox.IsChecked = mValue;
		mCheckBox.OnCheckedChanged.Add(new (cb, val) => {
			mValue = val;
			Setter?.Invoke(val);
			NotifyValueChanged();
		});
		return mCheckBox;
	}

	public override void RefreshView()
	{
		if (mCheckBox != null) mCheckBox.IsChecked = mValue;
	}
}

/// String property editor - EditText.
public class StringEditor : PropertyEditor
{
	private String mValue = new .() ~ delete _;
	private EditText mEditText;

	public StringView Value
	{
		get => mValue;
		set { mValue.Set(value); if (mEditText != null) mEditText.SetText(value); }
	}

	public delegate void(StringView) Setter ~ delete _;

	public this(StringView name, StringView initialValue, delegate void(StringView) setter = null, StringView category = default)
		: base(name, category)
	{
		mValue.Set(initialValue);
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		mEditText = new EditText();
		mEditText.SetText(mValue);
		mEditText.OnTextChanged.Add(new (e) => {
			mValue.Set(mEditText.Text);
			Setter?.Invoke(mValue);
			NotifyValueChanged();
		});
		return mEditText;
	}

	public override void RefreshView()
	{
		if (mEditText != null) mEditText.SetText(mValue);
	}
}

/// Float property editor - NumericField with decimal places.
public class FloatEditor : PropertyEditor
{
	private double mValue;
	private NumericField mField;
	private double mMin;
	private double mMax;
	private double mStep;
	private int32 mDecimalPlaces;

	public double Value
	{
		get => mValue;
		set { mValue = value; if (mField != null) mField.Value = value; }
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
		mField = new NumericField();
		mField.Min = mMin; mField.Max = mMax; mField.Step = mStep;
		mField.DecimalPlaces = mDecimalPlaces;
		mField.Value = mValue;
		mField.OnValueChanged.Add(new (nf, val) => {
			mValue = val;
			Setter?.Invoke(val);
			NotifyValueChanged();
		});
		return mField;
	}

	public override void RefreshView()
	{
		if (mField != null) mField.Value = mValue;
	}
}

/// Integer property editor - NumericField with 0 decimal places.
public class IntEditor : PropertyEditor
{
	private int64 mValue;
	private NumericField mField;
	private double mMin;
	private double mMax;

	public int64 Value
	{
		get => mValue;
		set { mValue = value; if (mField != null) mField.Value = (double)value; }
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
		mField = new NumericField();
		mField.Min = mMin; mField.Max = mMax; mField.Step = 1;
		mField.DecimalPlaces = 0;
		mField.Value = (double)mValue;
		mField.OnValueChanged.Add(new (nf, val) => {
			mValue = (int64)val;
			Setter?.Invoke(mValue);
			NotifyValueChanged();
		});
		return mField;
	}

	public override void RefreshView()
	{
		if (mField != null) mField.Value = (double)mValue;
	}
}

/// Color property editor - ColorView swatch that opens a ColorPicker popup on click.
public class ColorEditor : PropertyEditor
{
	private Color mValue;
	private ColorView mSwatch;

	public Color Value
	{
		get => mValue;
		set { mValue = value; if (mSwatch != null) mSwatch.Color = value; }
	}

	public delegate void(Color) Setter ~ delete _;

	public this(StringView name, Color initialValue, delegate void(Color) setter = null,
		StringView category = default) : base(name, category)
	{
		mValue = initialValue;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		mSwatch = new ClickableColorSwatch(this);
		mSwatch.Color = mValue;
		mSwatch.Cursor = .Hand;
		return mSwatch;
	}

	/// ColorView that opens a ColorPicker dialog on click.
	private class ClickableColorSwatch : ColorView
	{
		private ColorEditor mEditor;

		public this(ColorEditor editor) { mEditor = editor; }

		public override void OnMouseDown(MouseEventArgs e)
		{
			if (e.Button != .Left || Context == null) return;

			let picker = new ColorPicker();
			picker.SetColor(mEditor.mValue);
			picker.SetOriginalColor(mEditor.mValue);
			picker.OnColorChanged.Add(new (p, color) =>
			{
				mEditor.mValue = color;
				mEditor.mSwatch.Color = color;
				mEditor.Setter?.Invoke(color);
				mEditor.NotifyValueChanged();
			});

			let dialog = new Dialog("Color Picker");
			dialog.SetContent(picker);
			dialog.AddButton("OK", .OK);
			dialog.AddButton("Cancel", .Cancel);
			dialog.Show(Context);
			e.Handled = true;
		}
	}

	public override void RefreshView()
	{
		if (mSwatch != null) mSwatch.Color = mValue;
	}
}

/// Range/slider property editor - Slider.
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
		mSlider.OnValueChanged.Add(new (s, val) => {
			mValue = val;
			Setter?.Invoke(val);
			NotifyValueChanged();
		});
		return mSlider;
	}

	public override void RefreshView()
	{
		if (mSlider != null) mSlider.Value = mValue;
	}
}
