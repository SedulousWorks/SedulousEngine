namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Particles;

/// Property editor for EmissionShape. Top row: shape Type dropdown. Below
/// that: conditional rows showing the parameters that apply to the chosen
/// type (size, cone angle, arc, emit-from-surface). Switching the type
/// rebuilds the conditional area so unused parameters don't clutter the UI.
class EmissionShapeEditor : PropertyEditor
{
	private EmissionShape* mPtr;
	private ComboBox mTypeCombo;
	private FlexLayout mParamsContainer;
	private bool mSyncing;

	private static readonly String[?] sTypeNames = .(
		"Point", "Sphere", "Hemisphere", "Cone", "Box", "Circle", "Edge");

	public this(StringView name, EmissionShape* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4;

		// Type dropdown.
		mTypeCombo = new ComboBox();
		for (let n in sTypeNames)
			mTypeCombo.AddItem(n);
		mTypeCombo.SelectedIndex = (int32)mPtr.Type;
		mTypeCombo.OnSelectionChanged.Add(new (cb, idx) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			BeginEdit();
			mPtr.Type = (EmissionShapeType)idx;
			NotifyValueChanged();
			EndEdit();
			mSyncing = false;
			RebuildParams();
		});
		column.AddView(mTypeCombo, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});

		// Parameter rows container - rebuilt on type change.
		mParamsContainer = new FlexLayout();
		mParamsContainer.Direction = .Vertical;
		mParamsContainer.Spacing = 2;
		column.AddView(mParamsContainer, new FlexLayout.LayoutParams() { Width = .Match });

		RebuildParams();

		return column;
	}

	private void RebuildParams()
	{
		while (mParamsContainer.ChildCount > 0)
			mParamsContainer.RemoveView(mParamsContainer.GetChildAt(0), true);

		switch (mPtr.Type)
		{
		case .Point:
			// No params.
		case .Sphere, .Hemisphere:
			AddRadiusRow();
			AddArcRow();
			AddSurfaceRow();
		case .Cone:
			AddConeAngleRow();
			AddRadiusRow();
			AddArcRow();
			AddSurfaceRow();
		case .Box:
			AddBoxSizeRow();
			AddSurfaceRow();
		case .Circle:
			AddRadiusRow();
			AddArcRow();
			AddSurfaceRow();
		case .Edge:
			AddHalfLengthRow();
		}

		mParamsContainer.Invalidate();
	}

	// Each Add*Row method creates a labeled NumericField bound to the
	// matching field on mPtr. Closures over `this` member-access so they
	// don't need explicit capture syntax (which would make them static).

	private void AddRadiusRow()
	{
		let field = MakeNumeric("", mPtr.Size.X, 0, 1000);
		field.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Size.X = (float)val; NotifyValueChanged(); mSyncing = false;
		});
		mParamsContainer.AddView(LabelWrap("Radius", field), new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddHalfLengthRow()
	{
		let field = MakeNumeric("", mPtr.Size.X, 0, 1000);
		field.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Size.X = (float)val; NotifyValueChanged(); mSyncing = false;
		});
		mParamsContainer.AddView(LabelWrap("Half Len", field), new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddConeAngleRow()
	{
		// Stored in radians; surface as degrees.
		let field = MakeNumeric("°", mPtr.ConeAngle * (float)(180.0 / Math.PI_d), 0, 180);
		field.DecimalPlaces = 1; field.Step = 1;
		field.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.ConeAngle = (float)(val * Math.PI_d / 180.0); NotifyValueChanged(); mSyncing = false;
		});
		mParamsContainer.AddView(LabelWrap("Cone", field), new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddArcRow()
	{
		// 0 = full 2π. Surface as degrees.
		let field = MakeNumeric("°", mPtr.Arc * (float)(180.0 / Math.PI_d), 0, 360);
		field.DecimalPlaces = 1; field.Step = 1;
		field.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Arc = (float)(val * Math.PI_d / 180.0); NotifyValueChanged(); mSyncing = false;
		});
		mParamsContainer.AddView(LabelWrap("Arc", field), new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddSurfaceRow()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		let lbl = new Label();
		lbl.SetText("Surface");
		lbl.FontSize.Value = 11;
		lbl.VAlign.Value = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)) });

		let check = new CheckBox();
		check.IsChecked.Value = mPtr.EmitFromSurface;
		check.OnCheckedChanged.Add(new (cb, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			BeginEdit();
			mPtr.EmitFromSurface = val;
			NotifyValueChanged();
			EndEdit();
			mSyncing = false;
		});
		row.AddView(check, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(20)), Height = .Fixed(.Px(20)) });

		mParamsContainer.AddView(row, new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddBoxSizeRow()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 3;

		let lbl = new Label();
		lbl.SetText("Half Ext");
		lbl.FontSize.Value = 11;
		lbl.VAlign.Value = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)) });

		let xf = MakeNumeric("X", mPtr.Size.X, 0, 1000);
		xf.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Size.X = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		let yf = MakeNumeric("Y", mPtr.Size.Y, 0, 1000);
		yf.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Size.Y = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		let zf = MakeNumeric("Z", mPtr.Size.Z, 0, 1000);
		zf.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true; mPtr.Size.Z = (float)val; NotifyValueChanged(); mSyncing = false;
		});

		row.AddView(xf, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(yf, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(zf, new FlexLayout.LayoutParams() { Grow = 1 });

		mParamsContainer.AddView(row, new FlexLayout.LayoutParams() { Width = .Match });
	}

	private NumericField MakeNumeric(StringView prefix, float initial, float min, float max)
	{
		let field = new ShapeNumericField(this);
		field.ShowSpinButtons.Value = false;
		field.Min = min; field.Max = max; field.Step = 0.1;
		field.DecimalPlaces = 3;
		if (prefix.Length > 0)
			field.SetPrefix(prefix);
		field.Value = initial;
		return field;
	}

	private View LabelWrap(StringView label, View inner)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		let lbl = new Label();
		lbl.SetText(label);
		lbl.FontSize.Value = 11;
		lbl.VAlign.Value = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)) });
		row.AddView(inner, new FlexLayout.LayoutParams() { Grow = 1 });
		return row;
	}

	private class ShapeNumericField : NumericField
	{
		private EmissionShapeEditor mEditor;
		public this(EmissionShapeEditor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			if (!mEditor.IsEditing) mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing) mEditor.EndEdit();
		}
	}

	public override void RefreshView()
	{
		if (mTypeCombo == null || mSyncing) return;
		mSyncing = true;
		mTypeCombo.SelectedIndex = (int32)mPtr.Type;
		mSyncing = false;
		RebuildParams();
	}
}
