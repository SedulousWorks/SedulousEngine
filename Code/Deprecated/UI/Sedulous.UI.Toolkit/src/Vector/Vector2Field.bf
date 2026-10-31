using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A standalone Float2 input: 2 numeric fields behind coloured axis letters.
class Vector2Field : AggregatingVectorField
{
	public Event<delegate void(Float2)> OnValueChanged ~ _.Dispose();

	private Float2 mValue = .Zero;

	public this()
	{
		BuildFields(-1e6, 1e6, 0.1, 3);
	}

	public Float2 Value => mValue;

	public void SetValue(Float2 value)
	{
		mValue = value;
		SyncToFields();
	}

	protected override int32 AxisCount => 2;

	protected override float GetComponent(int32 axis) => mValue[axis];

	protected override void SetComponentFromField(int32 axis, float value)
	{
		mValue[axis] = value;
		OnValueChanged(mValue);
	}
}
