using System;
using Sedulous.Core;

namespace Sedulous.UI.Toolkit;

/// A four component vector: X, Y, Z and W. A rectangle in texture space, a plane, a tangent.
class Float4Editor : VectorEditorBase
{
	/// OWNED.
	public delegate void(Float4) Setter ~ delete _;

	private Float4 mValue;

	/// CONSUMES the setter.
	public this(StringView name, Float4 value, float min = -100000.0f, float max = 100000.0f,
		float step = 0.1f, delegate void(Float4) setter = null, StringView category = default)
		: base(name, category, min, max, step)
	{
		Setter = setter;
		mValue = value;
	}

	public Float4 Value => mValue;

	public void SetValue(Float4 value)
	{
		mValue = value;
		if (!mSyncing)
			RefreshView();
	}

	protected override int32 AxisCount => 4;

	protected override float GetComponent(int32 axis) => mValue[axis];

	protected override void SetComponent(int32 axis, float value)
	{
		mValue[axis] = value;
		if (Setter != null)
			Setter(mValue);
	}
}
