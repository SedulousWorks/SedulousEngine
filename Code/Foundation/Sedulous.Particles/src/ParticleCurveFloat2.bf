using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A two dimensional curve over normalised lifetime, cubic per component.
///
/// PARALLEL ARRAYS rather than an array of keys, which is what Sedulous shipped: the
/// component sweeps read one array at a time.
[Scriptable]
struct ParticleCurveFloat2
{
	public float[ParticleCurve.MaxKeys] Times = .();
	public Float2[ParticleCurve.MaxKeys] Values = .();
	public Float2[ParticleCurve.MaxKeys] TangentsIn = .();
	public Float2[ParticleCurve.MaxKeys] TangentsOut = .();
	[Scriptable]
	public int32 KeyCount = 0;

	public this() {}

	public bool IsActive => KeyCount > 0;

	public Float2 Evaluate(float t)
	{
		if (KeyCount <= 0)
			return .(0, 0);
		if (KeyCount == 1)
			return Values[0];
		if (t <= Times[0])
			return Values[0];
		if (t >= Times[KeyCount - 1])
			return Values[KeyCount - 1];

		var i = 0;
		while ((i < (KeyCount - 1)) && (t > Times[i + 1]))
			i++;

		let segment = Times[i + 1] - Times[i];
		let localT = (segment > ParticleCurve.MinSegment) ? ((t - Times[i]) / segment) : 0.0f;
		return .(
			ParticleCurve.Hermite(Values[i].X, TangentsOut[i].X * segment, Values[i + 1].X,
				TangentsIn[i + 1].X * segment, localT),
			ParticleCurve.Hermite(Values[i].Y, TangentsOut[i].Y * segment, Values[i + 1].Y,
				TangentsIn[i + 1].Y * segment, localT));
	}

	public bool AddKey(float time, Float2 value, Float2 tangentIn = .(0, 0),
		Float2 tangentOut = .(0, 0)) mut
	{
		if (KeyCount >= ParticleCurve.MaxKeys)
			return false;

		var index = KeyCount;
		while ((index > 0) && (Times[index - 1] > time))
		{
			Times[index] = Times[index - 1];
			Values[index] = Values[index - 1];
			TangentsIn[index] = TangentsIn[index - 1];
			TangentsOut[index] = TangentsOut[index - 1];
			index--;
		}
		Times[index] = time;
		Values[index] = value;
		TangentsIn[index] = tangentIn;
		TangentsOut[index] = tangentOut;
		KeyCount++;
		return true;
	}

	public static ParticleCurveFloat2 Constant(Float2 value)
	{
		var curve = ParticleCurveFloat2();
		curve.AddKey(0.0f, value);
		return curve;
	}

	public static ParticleCurveFloat2 Linear(Float2 from, Float2 to)
	{
		var curve = ParticleCurveFloat2();
		curve.AddKey(0.0f, from);
		curve.AddKey(1.0f, to);
		return curve;
	}

	/// COUNT BOUND, see ParticleCurveFloat.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "keyCount", ref KeyCount);
		KeyCount = Clamp(KeyCount, 0, (int32)ParticleCurve.MaxKeys);
		for (int32 i = 0; i < KeyCount; i++)
		{
			SerializeValue(ar, "time", ref Times[i]);
			SerializeValue(ar, "value", ref Values[i]);
			SerializeValue(ar, "tangentIn", ref TangentsIn[i]);
			SerializeValue(ar, "tangentOut", ref TangentsOut[i]);
		}
	}
}
