using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// What the standalone vector inputs share: a row of numeric fields behind coloured letters,
/// and ONE edit transaction across the whole row.
///
/// THE AGGREGATION is the point. Each field opens and closes its own edit as focus moves, so
/// tabbing X to Y to Z would otherwise be three transactions and three undo steps for one
/// gesture. A counter holds the row open while any field is being edited.
///
/// The close is DEFERRED through the mutation queue, because a focus jump arrives as the old
/// field's end followed by the new field's begin. Closing immediately would end the row's edit
/// in the gap between the two; deferring lets the incoming begin cancel the pending close.
///
/// FACTORED over the axis count, rather than Vector2, Vector3 and Vector4 as three full
/// copies differing only in how many fields they build and which component each writes.
abstract class AggregatingVectorField : FlexLayout
{
	private const int MaxAxes = 4;
	private static readonly StringView[MaxAxes] AxisLetters = .("X", "Y", "Z", "W");

	public Event<delegate void(AggregatingVectorField)> OnEditBegan ~ _.Dispose();
	public Event<delegate void(AggregatingVectorField)> OnEditEnded ~ _.Dispose();

	/// BORROWED: the child list owns the fields. Zero filled, so unused axes stay null.
	protected NumericField[MaxAxes] mFields = .();
	protected bool mSyncing = false;

	private int32 mEditCount = 0;
	private bool mPendingEnd = false;

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4.0f;
	}

	protected abstract int32 AxisCount { get; }

	protected abstract float GetComponent(int32 axis);

	/// Writes one component from its field and reports the new whole value.
	protected abstract void SetComponentFromField(int32 axis, float value);

	/// Builds the row. Called by a subclass's constructor, which is also where the ranges are
	/// decided, because an Euler angle field wants different ones from a position field.
	protected void BuildFields(double min, double max, double step, int32 decimalPlaces)
	{
		for (int32 axis = 0; axis < AxisCount; axis++)
		{
			let field = new NumericField();
			field.AddClass("property-field");
			// NO spin buttons: four of them across a row would leave no room for the numbers.
			field.ShowSpinButtons.Value = false;
			field.SetMin(min);
			field.SetMax(max);
			field.SetStep(step);
			field.SetDecimalPlaces(decimalPlaces);
			field.SetPrefix(new AxisLabel(AxisLetters[axis], ColorFor(axis)));
			field.SetValue(GetComponent(axis));

			let boundAxis = axis;
			field.OnValueChanged.Add(new (sender, value) =>
				{
					if (!mSyncing)
						SetComponentFromField(boundAxis, (float)value);
				});

			WireChildEditEvents(field);
			mFields[axis] = field;

			LayoutStyle style = .();
			style.FlexGrow = 1.0f;
			style.Height = SizeSpec.Match();
			AddView(field, style);
		}
	}

	/// Pushes the current value out to the fields, under the guard so the writes are not read
	/// back as edits.
	protected void SyncToFields()
	{
		if (mSyncing || (mFields[0] == null))
			return;

		mSyncing = true;
		for (int32 axis = 0; axis < AxisCount; axis++)
			mFields[axis].SetValue(GetComponent(axis));
		mSyncing = false;
	}

	// ---- Field configuration, applied to every axis at once -------------------------------------

	public void SetRange(double min, double max)
	{
		for (int32 axis = 0; axis < AxisCount; axis++)
		{
			mFields[axis].SetMin(min);
			mFields[axis].SetMax(max);
		}
	}

	public double Step => mFields[0].Step;

	public void SetStep(double value)
	{
		for (int32 axis = 0; axis < AxisCount; axis++)
			mFields[axis].SetStep(value);
	}

	public int32 DecimalPlaces => mFields[0].DecimalPlaces;

	public void SetDecimalPlaces(int32 value)
	{
		for (int32 axis = 0; axis < AxisCount; axis++)
			mFields[axis].SetDecimalPlaces(value);
	}

	public bool ShowSpinButtons => mFields[0].ShowSpinButtons.Value;

	public void SetShowSpinButtons(bool value)
	{
		for (int32 axis = 0; axis < AxisCount; axis++)
			mFields[axis].ShowSpinButtons.Value = value;
	}

	// ---- The shared transaction -----------------------------------------------------------------

	private void WireChildEditEvents(NumericField field)
	{
		field.OnEditBegan.Add(new (sender) =>
			{
				// A begin CANCELS a pending close, which is what makes a focus jump between
				// sibling fields one transaction rather than two.
				mPendingEnd = false;
				if (mEditCount == 0)
					OnEditBegan(this);
				mEditCount++;
			});

		field.OnEditEnded.Add(new (sender) =>
			{
				mEditCount--;
				if (mEditCount != 0)
					return;

				mPendingEnd = true;

				// With no context there is no queue to defer through, and nothing is
				// dispatching either, so it closes at once.
				if (Context == null)
				{
					mPendingEnd = false;
					OnEditEnded(this);
					return;
				}

				Context.MutationQueue.QueueAction(new () =>
					{
						if (!mPendingEnd)
							return;

						mPendingEnd = false;
						OnEditEnded(this);
					});
			});
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
