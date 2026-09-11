using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// What the Float2, Float3 and Float4 editors share: a row of numeric fields, one per axis,
/// each behind a coloured letter.
///
/// FACTORED rather than written three times. The C++ carries three copies and says so, calling
/// the second and third "mechanical siblings" of the first; every line of them differs only in
/// the axis count and which component a field writes. Those two things are what a subclass
/// supplies here, and its public surface stays exactly the C++ one, typed to its own vector.
///
/// The transaction spans the WHOLE row: focus moving from X to Y is still one edit, because a
/// person typing a position is doing one thing, not three.
abstract class VectorEditorBase : PropertyEditor
{
	private const int MaxAxes = 4;

	/// A numeric field that reports focus changes back to the editor.
	private class FocusReportingField : NumericField
	{
		private VectorEditorBase mEditor;

		public this(VectorEditorBase editor)
		{
			mEditor = editor;
		}

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

	private static readonly StringView[MaxAxes] AxisLetters = .("X", "Y", "Z", "W");

	protected float mMin;
	protected float mMax;
	protected float mStep;
	protected bool mSyncing = false;

	/// BORROWED: the row tree owns the fields. Zero filled, so the unused axes stay null.
	private NumericField[MaxAxes] mFields = .();

	public this(StringView name, StringView category, float min, float max, float step)
		: base(name, category)
	{
		mMin = min;
		mMax = max;
		mStep = step;
	}

	/// How many components this editor shows.
	protected abstract int32 AxisCount { get; }

	protected abstract float GetComponent(int32 axis);

	/// Writes one component and reports the WHOLE vector to the caller's setter, because a
	/// setter takes the value, not a piece of it.
	protected abstract void SetComponent(int32 axis, float value);

	public override void RefreshView()
	{
		if ((mFields[0] == null) || mSyncing)
			return;

		mSyncing = true;
		for (int32 axis = 0; axis < AxisCount; axis++)
			mFields[axis].SetValue(GetComponent(axis));
		mSyncing = false;
	}

	protected override View CreateEditorView()
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4.0f;

		for (int32 axis = 0; axis < AxisCount; axis++)
		{
			let field = MakeField(axis);
			mFields[axis] = field;

			let boundAxis = axis;
			field.OnValueChanged.Add(new [=](sender, value) =>
				{
					if (mSyncing)
						return;

					mSyncing = true;
					SetComponent(boundAxis, (float)value);
					NotifyValueChanged();
					mSyncing = false;
				});

			// Every axis grows equally, so the components stay the same width as each other
			// however wide the inspector is.
			LayoutStyle style = .();
			style.FlexGrow = 1.0f;
			row.AddView(field, style);
		}

		return row;
	}

	private NumericField MakeField(int32 axis)
	{
		let field = new FocusReportingField(this);
		field.AddClass("property-field");
		// NO spin buttons: four of them across a row would leave no room for the numbers.
		field.ShowSpinButtons.Value = false;
		field.SetMin(mMin);
		field.SetMax(mMax);
		field.SetStep(mStep);
		field.SetDecimalPlaces(3);
		field.SetValue(GetComponent(axis));
		field.SetPrefix(new AxisLabel(AxisLetters[axis], ColorFor(axis)));
		return field;
	}

	private static Color ColorFor(int32 axis)
	{
		switch (axis)
		{
		case 0: return AxisColors.X;
		case 1: return AxisColors.Y;
		case 2: return AxisColors.Z;
		default: return AxisColors.W;
		}
	}
}
