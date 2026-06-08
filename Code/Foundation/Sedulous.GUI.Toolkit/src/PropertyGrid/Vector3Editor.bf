namespace Sedulous.GUI.Toolkit;

using System;
using Sedulous.GUI;
using Sedulous.Core.Mathematics;

/// Property editor for Vector3 values. Three NumericFields (X, Y, Z) side by side
/// with axis labels.
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
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		// X - colored prefix label inside NumericField
		mXField = new VectorNumericField(this, 0);
		mXField.ShowSpinButtons.Value = false;
		mXField.Min = mMin; mXField.Max = mMax; mXField.Step = mStep;
		mXField.DecimalPlaces = 3;
		mXField.Value = mValue.X;
		mXField.SetPrefix(new AxisLabel("X", .(220, 80, 80, 255)));
		mXField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue.X = (float)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		row.AddView(mXField, new FlexLayout.LayoutParams() { Grow = 1 });

		// Y
		mYField = new VectorNumericField(this, 1);
		mYField.ShowSpinButtons.Value = false;
		mYField.Min = mMin; mYField.Max = mMax; mYField.Step = mStep;
		mYField.DecimalPlaces = 3;
		mYField.Value = mValue.Y;
		mYField.SetPrefix(new AxisLabel("Y", .(80, 200, 80, 255)));
		mYField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue.Y = (float)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		row.AddView(mYField, new FlexLayout.LayoutParams() { Grow = 1 });

		// Z
		mZField = new VectorNumericField(this, 2);
		mZField.ShowSpinButtons.Value = false;
		mZField.Min = mMin; mZField.Max = mMax; mZField.Step = mStep;
		mZField.DecimalPlaces = 3;
		mZField.Value = mValue.Z;
		mZField.SetPrefix(new AxisLabel("Z", .(80, 120, 220, 255)));
		mZField.OnValueChanged.Add(new (nf, val) => {
			if (!mSyncing) { mSyncing = true; mValue.Z = (float)val; Setter?.Invoke(mValue); NotifyValueChanged(); mSyncing = false; }
		});
		row.AddView(mZField, new FlexLayout.LayoutParams() { Grow = 1 });

		return row;
	}

	/// Colored axis label used as a prefix View inside NumericField.
	private class AxisLabel : View
	{
		private String mText ~ delete _;
		private Color mColor;

		public this(StringView text, Color color)
		{
			mText = new String(text);
			mColor = color;
		}

		protected override void OnMeasure(BoxConstraints constraints)
		{
			float w = 12, h = 14;
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(11);
				if (font != null)
				{
					w = font.Font.MeasureString(mText);
					h = font.Font.Metrics.LineHeight;
				}
			}
			MeasuredSize = .(constraints.ConstrainWidth(w), constraints.ConstrainHeight(h));
		}

		public override void OnDraw(UIDrawContext ctx)
		{
			let font = ctx.FontService?.GetFont(11);
			if (font != null)
				ctx.VG.DrawText(mText, font, .(0, 0, Width, Height), .Center, .Middle, mColor);
		}
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
