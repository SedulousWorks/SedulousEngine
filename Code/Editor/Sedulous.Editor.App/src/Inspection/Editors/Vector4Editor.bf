namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;

/// Property editor for a generic Vector4 (no color semantics). Four
/// NumericFields side-by-side, X/Y/Z/W labels. Used by the descriptor's
/// Vec4 method when a field is tagged `[Property]` without the `.Color`
/// editor hint (e.g. plane equations, homogeneous coords, packed pairs).
class Vector4Editor : PropertyEditor
{
	private Vector4* mPtr;
	private NumericField mX, mY, mZ, mW;
	private bool mSyncing;

	public this(StringView name, Vector4* ptr, StringView category = default) : base(name, category)
	{
		mPtr = ptr;
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		mX = MakeField("X", mPtr.X);
		mX.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.X = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mY = MakeField("Y", mPtr.Y);
		mY.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Y = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mZ = MakeField("Z", mPtr.Z);
		mZ.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.Z = (float)val; NotifyValueChanged(); mSyncing = false; } });

		mW = MakeField("W", mPtr.W);
		mW.OnValueChanged.Add(new (nf, val) => { if (!mSyncing) { mSyncing = true; mPtr.W = (float)val; NotifyValueChanged(); mSyncing = false; } });

		row.AddView(mX, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(mY, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(mZ, new FlexLayout.LayoutParams() { Grow = 1 });
		row.AddView(mW, new FlexLayout.LayoutParams() { Grow = 1 });

		return row;
	}

	private NumericField MakeField(StringView prefix, float initial)
	{
		let f = new Vec4NumericField(this);
		f.ShowSpinButtons.Value = false;
		f.Min = -1e6f; f.Max = 1e6f; f.Step = 0.1;
		f.DecimalPlaces = 3;
		f.SetPrefix(prefix);
		f.Value = initial;
		return f;
	}

	private class Vec4NumericField : NumericField
	{
		private Vector4Editor mEditor;
		public this(Vector4Editor editor) { mEditor = editor; }

		public override void OnFocusGained()
		{
			base.OnFocusGained();
			if (!mEditor.IsEditing) mEditor.BeginEdit();
		}

		public override void OnFocusLost()
		{
			base.OnFocusLost();
			if (mEditor.IsEditing && !AnyFieldFocused()) mEditor.EndEdit();
		}

		private bool AnyFieldFocused()
		{
			return (mEditor.mX != null && mEditor.mX.IsFocused) ||
				   (mEditor.mY != null && mEditor.mY.IsFocused) ||
				   (mEditor.mZ != null && mEditor.mZ.IsFocused) ||
				   (mEditor.mW != null && mEditor.mW.IsFocused);
		}
	}

	public override void RefreshView()
	{
		if (mX == null || mSyncing) return;
		mSyncing = true;
		mX.Value = mPtr.X;
		mY.Value = mPtr.Y;
		mZ.Value = mPtr.Z;
		mW.Value = mPtr.W;
		mSyncing = false;
	}
}
