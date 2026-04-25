namespace Sedulous.UI.Toolkit;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Property editor for Vector3 values. Three NumericFields (X, Y, Z) side by side
/// with colored axis labels.
public class Vector3Editor : PropertyEditor
{
	private Vector3 mValue;
	private float mMin;
	private float mMax;
	private float mStep;
	private NumericField mXField;
	private NumericField mYField;
	private NumericField mZField;
	private bool mSyncing;

	public Vector3 Value
	{
		get => mValue;
		set
		{
			mValue = value;
			if (!mSyncing) RefreshView();
		}
	}

	public delegate void(Vector3) Setter ~ delete _;

	public this(StringView name, Vector3 value, float min = -100000, float max = 100000,
		float step = 0.1f, delegate void(Vector3) setter = null, StringView category = default)
		: base(name, category)
	{
		mValue = value;
		mMin = min; mMax = max; mStep = step;
		Setter = setter;
	}

	protected override View CreateEditorView()
	{
		let row = new LinearLayout();
		row.Orientation = .Horizontal;
		row.Spacing = 2;

		// X
		let xLabel = new Label();
		xLabel.SetText("X");
		xLabel.FontSize = 11;
		xLabel.TextColor = .(220, 80, 80, 255); // Red
		row.AddView(xLabel, new LinearLayout.LayoutParams() {
			Width = LayoutParams.WrapContent, Height = LayoutParams.MatchParent
		});

		mXField = new VectorNumericField(this, 0);
		mXField.Min = mMin; mXField.Max = mMax; mXField.Step = mStep;
		mXField.DecimalPlaces = 3;
		mXField.Value = mValue.X;
		mXField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue.X = (float)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		row.AddView(mXField, new LinearLayout.LayoutParams() {
			Width = 0, Height = LayoutParams.MatchParent, Weight = 1
		});

		// Y
		let yLabel = new Label();
		yLabel.SetText("Y");
		yLabel.FontSize = 11;
		yLabel.TextColor = .(80, 200, 80, 255); // Green
		row.AddView(yLabel, new LinearLayout.LayoutParams() {
			Width = LayoutParams.WrapContent, Height = LayoutParams.MatchParent
		});

		mYField = new VectorNumericField(this, 1);
		mYField.Min = mMin; mYField.Max = mMax; mYField.Step = mStep;
		mYField.DecimalPlaces = 3;
		mYField.Value = mValue.Y;
		mYField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue.Y = (float)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		row.AddView(mYField, new LinearLayout.LayoutParams() {
			Width = 0, Height = LayoutParams.MatchParent, Weight = 1
		});

		// Z
		let zLabel = new Label();
		zLabel.SetText("Z");
		zLabel.FontSize = 11;
		zLabel.TextColor = .(80, 120, 220, 255); // Blue
		row.AddView(zLabel, new LinearLayout.LayoutParams() {
			Width = LayoutParams.WrapContent, Height = LayoutParams.MatchParent
		});

		mZField = new VectorNumericField(this, 2);
		mZField.Min = mMin; mZField.Max = mMax; mZField.Step = mStep;
		mZField.DecimalPlaces = 3;
		mZField.Value = mValue.Z;
		mZField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue.Z = (float)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		row.AddView(mZField, new LinearLayout.LayoutParams() {
			Width = 0, Height = LayoutParams.MatchParent, Weight = 1
		});

		return row;
	}

	/// NumericField subclass that tracks edit transactions via focus.
	private class VectorNumericField : NumericField
	{
		private Vector3Editor mEditor;
		private int32 mAxis;

		public this(Vector3Editor editor, int32 axis) { mEditor = editor; mAxis = axis; }

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

	public override void RefreshView()
	{
		if (mXField != null && !mSyncing)
		{
			mSyncing = true;
			mXField.Value = mValue.X;
			mYField.Value = mValue.Y;
			mZField.Value = mValue.Z;
			mSyncing = false;
		}
	}
}
