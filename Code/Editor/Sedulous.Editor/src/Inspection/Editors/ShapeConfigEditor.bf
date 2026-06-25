namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Physics;

/// Property editor for ShapeConfig (Box / Sphere / Capsule / Cylinder /
/// Plane). Top row is a shape-type dropdown; below it sit only the
/// sub-fields relevant to the selected type. Switching the type rebuilds
/// the parameter rows so unused fields don't clutter the inspector.
/// Mirrors EmissionShapeEditor.
///
/// `mOnChanged` (optional) fires after each user edit so the owning
/// component can flag its physics body for rebuild
/// (RigidBodyComponent.NeedsShapeUpdate). The editor owns the delegate.
class ShapeConfigEditor : PropertyEditor
{
	private ShapeConfig* mPtr;
	private delegate void() mOnChanged ~ delete _;
	private ComboBox mTypeCombo;
	private FlexLayout mParamsContainer;
	private bool mSyncing;

	private static readonly String[?] sTypeNames = .(
		"Box", "Sphere", "Capsule", "Cylinder", "Plane");

	public this(StringView name, ShapeConfig* ptr, delegate void() onChanged = null,
		StringView category = default) : base(name, category)
	{
		mPtr = ptr;
		mOnChanged = onChanged;
	}

	protected override View CreateEditorView()
	{
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 4;

		// Shape-type dropdown.
		mTypeCombo = new ComboBox();
		for (let n in sTypeNames)
			mTypeCombo.AddItem(n);
		mTypeCombo.SelectedIndex = (int32)mPtr.Type;
		mTypeCombo.OnSelectionChanged.Add(new (cb, idx) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			BeginEdit();
			mPtr.Type = (ShapeType)idx;
			NotifyValueChanged();
			EndEdit();
			mSyncing = false;
			mOnChanged?.Invoke();
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
		case .Box:
			AddBoxExtentsRow();
		case .Sphere:
			AddRadiusRow();
		case .Capsule, .Cylinder:
			AddRadiusRow();
			AddHalfHeightRow();
		case .Plane:
			// No parameters.
		}

		mParamsContainer.Invalidate();
	}

	private void AddRadiusRow()
	{
		let field = MakeNumeric("", mPtr.Radius, 0.001f, 1000);
		field.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.Radius = (float)val;
			NotifyValueChanged();
			mSyncing = false;
			mOnChanged?.Invoke();
		});
		mParamsContainer.AddView(LabelWrap("Radius", field), new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddHalfHeightRow()
	{
		let field = MakeNumeric("", mPtr.HalfHeight, 0.001f, 1000);
		field.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.HalfHeight = (float)val;
			NotifyValueChanged();
			mSyncing = false;
			mOnChanged?.Invoke();
		});
		mParamsContainer.AddView(LabelWrap("Half Height", field), new FlexLayout.LayoutParams() { Width = .Match });
	}

	private void AddBoxExtentsRow()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 3;

		let lbl = new Label();
		lbl.SetText("Half Ext");
		lbl.FontSize.Value = 11;
		lbl.VAlign.Value = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)) });

		let xf = MakeNumeric("X", mPtr.HalfExtents.X, 0.001f, 1000);
		xf.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.HalfExtents.X = (float)val;
			NotifyValueChanged();
			mSyncing = false;
			mOnChanged?.Invoke();
		});

		let yf = MakeNumeric("Y", mPtr.HalfExtents.Y, 0.001f, 1000);
		yf.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.HalfExtents.Y = (float)val;
			NotifyValueChanged();
			mSyncing = false;
			mOnChanged?.Invoke();
		});

		let zf = MakeNumeric("Z", mPtr.HalfExtents.Z, 0.001f, 1000);
		zf.OnValueChanged.Add(new (nf, val) =>
		{
			if (mSyncing) return;
			mSyncing = true;
			mPtr.HalfExtents.Z = (float)val;
			NotifyValueChanged();
			mSyncing = false;
			mOnChanged?.Invoke();
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
		private ShapeConfigEditor mEditor;
		public this(ShapeConfigEditor editor) { mEditor = editor; }

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
