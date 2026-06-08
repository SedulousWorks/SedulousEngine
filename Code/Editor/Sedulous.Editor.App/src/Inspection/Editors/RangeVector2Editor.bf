namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for RangeVector2 (Min/Max Vector2 pair). Two rows of two
/// NumericFields - "Min" row then "Max" row, each with X/Y. Writes through
/// the field pointer captured at construction.
class RangeVector2Editor : PropertyEditor
{
	private RangeVector2* mPtr;
	private float mMin;
	private float mMax;
	private NumericField mMinX, mMinY, mMaxX, mMaxY;
	private bool mSyncing;

	public this(StringView name, RangeVector2* ptr, float min = -1e6f, float max = 1e6f,
		StringView category = default) : base(name, category)
	{
		mPtr = ptr;
		mMin = min;
		mMax = max;
	}

	protected override View CreateEditorView()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 2;

		mMinX = MakeField("X", mPtr.Min.X);
		mMinX.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Min.X = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		mMinY = MakeField("Y", mPtr.Min.Y);
		mMinY.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Min.Y = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		mMaxX = MakeField("X", mPtr.Max.X);
		mMaxX.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Max.X = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		mMaxY = MakeField("Y", mPtr.Max.Y);
		mMaxY.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Max.Y = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		column.AddView(BuildRow("Min", mMinX, mMinY), new FlexLayout.LayoutParams() { Width = .Match });
		column.AddView(BuildRow("Max", mMaxX, mMaxY), new FlexLayout.LayoutParams() { Width = .Match });

		return column;
	}

	private NumericField MakeField(StringView prefix, float initial)
	{
		let field = new RangeNumericField(this);
		field.ShowSpinButtons.Value = false;
		field.Min = mMin; field.Max = mMax; field.Step = 0.1;
		field.DecimalPlaces = 3;
		field.SetPrefix(prefix);
		field.Value = initial;
		return field;
	}

	private View BuildRow(StringView label, NumericField xf, NumericField yf)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		let lbl = new Label();
		lbl.SetText(label);
		lbl.FontSize.Value = 11;
		lbl.VAlign.Value = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(28)) });

		row.AddView(xf, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(yf, new FlexLayout.LayoutParams() { Grow = 1 });
		return row;
	}

	private class RangeNumericField : NumericField
	{
		private RangeVector2Editor mEditor;
		public this(RangeVector2Editor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			if (!mEditor.IsEditing) mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing && !AnyFieldFocused())
				mEditor.EndEdit();
		}

		private bool AnyFieldFocused()
		{
			return (mEditor.mMinX != null && mEditor.mMinX.IsFocused) ||
				   (mEditor.mMinY != null && mEditor.mMinY.IsFocused) ||
				   (mEditor.mMaxX != null && mEditor.mMaxX.IsFocused) ||
				   (mEditor.mMaxY != null && mEditor.mMaxY.IsFocused);
		}
	}

	public override void RefreshView()
	{
		if (mMinX == null || mSyncing) return;
		mSyncing = true;
		mMinX.Value = mPtr.Min.X; mMinY.Value = mPtr.Min.Y;
		mMaxX.Value = mPtr.Max.X; mMaxY.Value = mPtr.Max.Y;
		mSyncing = false;
	}
}
