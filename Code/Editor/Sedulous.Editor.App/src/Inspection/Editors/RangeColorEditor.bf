namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for RangeColor (Min/Max Vector4 pair, HDR-allowed).
/// Two rows of four NumericFields (R/G/B/A). The existing ColorEditor uses
/// 8-bit Color and a picker dialog - particle colors need HDR float channels,
/// so v1 uses plain numeric fields. A real HDR color picker can replace this
/// later without changing the descriptor wiring.
class RangeColorEditor : PropertyEditor
{
	private RangeColor* mPtr;
	private NumericField mMinR, mMinG, mMinB, mMinA, mMaxR, mMaxG, mMaxB, mMaxA;
	private bool mSyncing;

	public this(StringView name, RangeColor* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 2;

		mMinR = MakeField("R", mPtr.Min.X);
		mMinR.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Min.X = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMinG = MakeField("G", mPtr.Min.Y);
		mMinG.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Min.Y = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMinB = MakeField("B", mPtr.Min.Z);
		mMinB.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Min.Z = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMinA = MakeField("A", mPtr.Min.W);
		mMinA.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Min.W = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMaxR = MakeField("R", mPtr.Max.X);
		mMaxR.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Max.X = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMaxG = MakeField("G", mPtr.Max.Y);
		mMaxG.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Max.Y = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMaxB = MakeField("B", mPtr.Max.Z);
		mMaxB.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Max.Z = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mMaxA = MakeField("A", mPtr.Max.W);
		mMaxA.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Max.W = (float)val; NotifyValueChanged(); mSyncing = false; } });

		column.AddView(BuildRow("Min", mMinR, mMinG, mMinB, mMinA), new FlexLayout.LayoutParams() { Width = .Match });
		column.AddView(BuildRow("Max", mMaxR, mMaxG, mMaxB, mMaxA), new FlexLayout.LayoutParams() { Width = .Match });

		return column;
	}

	private NumericField MakeField(StringView prefix, float initial)
	{
		let field = new RangeNumericField(this);
		field.ShowSpinButtons = false;
		field.Min = 0; field.Max = 8; field.Step = 0.05;
		field.DecimalPlaces = 3;
		field.SetPrefix(prefix);
		field.Value = initial;
		return field;
	}

	private View BuildRow(StringView label, NumericField r, NumericField g, NumericField b, NumericField a)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 3;

		let lbl = new Label();
		lbl.SetText(label);
		lbl.FontSize = 11;
		lbl.VAlign = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(28)) });

		row.AddView(r, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(g, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(b, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(a, new FlexLayout.LayoutParams() { Grow = 1 });
		return row;
	}

	private class RangeNumericField : NumericField
	{
		private RangeColorEditor mEditor;
		public this(RangeColorEditor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			if (!mEditor.IsEditing) mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing && !mEditor.AnyFieldFocused())
				mEditor.EndEdit();
		}
	}

	private bool AnyFieldFocused()
	{
		return Focused(mMinR) || Focused(mMinG) || Focused(mMinB) || Focused(mMinA)
			|| Focused(mMaxR) || Focused(mMaxG) || Focused(mMaxB) || Focused(mMaxA);
	}

	private static bool Focused(NumericField f) => f != null && f.IsFocused;

	public override void RefreshView()
	{
		if (mMinR == null || mSyncing) return;
		mSyncing = true;
		mMinR.Value = mPtr.Min.X; mMinG.Value = mPtr.Min.Y; mMinB.Value = mPtr.Min.Z; mMinA.Value = mPtr.Min.W;
		mMaxR.Value = mPtr.Max.X; mMaxG.Value = mPtr.Max.Y; mMaxB.Value = mPtr.Max.Z; mMaxA.Value = mPtr.Max.W;
		mSyncing = false;
	}
}
