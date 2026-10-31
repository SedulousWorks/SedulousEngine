using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A two component vector: X and Y side by side.
class Float2Editor : VectorEditorBase
{
	/// OWNED.
	public delegate void(Float2) Setter ~ delete _;

	private Float2 mValue;

	/// CONSUMES the setter.
	public this(StringView name, Float2 value, float min = -100000.0f, float max = 100000.0f,
		float step = 0.1f, delegate void(Float2) setter = null, StringView category = default)
		: base(name, category, min, max, step)
	{
		Setter = setter;
		mValue = value;
	}

	public Float2 Value => mValue;

	public void SetValue(Float2 value)
	{
		mValue = value;
		if (!mSyncing)
			RefreshView();
	}

	protected override int32 AxisCount => 2;

	protected override float GetComponent(int32 axis) => mValue[axis];

	protected override void SetComponent(int32 axis, float value)
	{
		mValue[axis] = value;
		if (Setter != null)
			Setter(mValue);
	}
}
