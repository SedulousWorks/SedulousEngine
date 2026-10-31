using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A three component vector: X, Y and Z side by side. The inspector's workhorse, since every
/// position, rotation and scale is one.
class Float3Editor : VectorEditorBase
{
	/// OWNED.
	public delegate void(Float3) Setter ~ delete _;

	private Float3 mValue;

	/// CONSUMES the setter.
	public this(StringView name, Float3 value, float min = -100000.0f, float max = 100000.0f,
		float step = 0.1f, delegate void(Float3) setter = null, StringView category = default)
		: base(name, category, min, max, step)
	{
		Setter = setter;
		mValue = value;
	}

	public Float3 Value => mValue;

	public void SetValue(Float3 value)
	{
		mValue = value;
		if (!mSyncing)
			RefreshView();
	}

	protected override int32 AxisCount => 3;

	protected override float GetComponent(int32 axis) => mValue[axis];

	protected override void SetComponent(int32 axis, float value)
	{
		mValue[axis] = value;
		if (Setter != null)
			Setter(mValue);
	}
}
