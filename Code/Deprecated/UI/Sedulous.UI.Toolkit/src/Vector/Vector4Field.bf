using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A standalone Float4 input: 4 numeric fields behind coloured axis letters.
class Vector4Field : AggregatingVectorField
{
	public Event<delegate void(Float4)> OnValueChanged ~ _.Dispose();

	private Float4 mValue = .Zero;

	public this()
	{
		BuildFields(-1e6, 1e6, 0.1, 3);
	}

	public Float4 Value => mValue;

	public void SetValue(Float4 value)
	{
		mValue = value;
		SyncToFields();
	}

	protected override int32 AxisCount => 4;

	protected override float GetComponent(int32 axis) => mValue[axis];

	protected override void SetComponentFromField(int32 axis, float value)
	{
		mValue[axis] = value;
		OnValueChanged(mValue);
	}
}
