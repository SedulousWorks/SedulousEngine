using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A standalone Float3 input: 3 numeric fields behind coloured axis letters.
class Vector3Field : AggregatingVectorField
{
	public Event<delegate void(Float3)> OnValueChanged ~ _.Dispose();

	private Float3 mValue = .Zero;

	public this()
	{
		BuildFields(-1e6, 1e6, 0.1, 3);
	}

	public Float3 Value => mValue;

	public void SetValue(Float3 value)
	{
		mValue = value;
		SyncToFields();
	}

	protected override int32 AxisCount => 3;

	protected override float GetComponent(int32 axis) => mValue[axis];

	protected override void SetComponentFromField(int32 axis, float value)
	{
		mValue[axis] = value;
		OnValueChanged(mValue);
	}
}
