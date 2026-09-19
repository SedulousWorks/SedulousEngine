using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A scalar curve over normalised lifetime, cubic between its keys.
///
/// NOT ACTIVE with no keys, which is what gates the behaviours that read one: an unset curve
/// is a behaviour that does nothing rather than a behaviour that drives everything to zero.
[Scriptable]
struct ParticleCurveFloat
{
	public CurveKeyFloat[ParticleCurve.MaxKeys] Keys = .();
	[Scriptable]
	public int32 KeyCount = 0;

	public this() {}

	public bool IsActive => KeyCount > 0;

	public float Evaluate(float t)
	{
		if (KeyCount <= 0)
			return 0.0f;
		if (KeyCount == 1)
			return Keys[0].Value;
		// CLAMPED at both ends: a lifetime outside the authored range holds rather than
		// extrapolating off the curve.
		if (t <= Keys[0].Time)
			return Keys[0].Value;
		if (t >= Keys[KeyCount - 1].Time)
			return Keys[KeyCount - 1].Value;

		var i = 0;
		while ((i < (KeyCount - 1)) && (t > Keys[i + 1].Time))
			i++;

		let k0 = Keys[i];
		let k1 = Keys[i + 1];
		let segment = k1.Time - k0.Time;
		let localT = (segment > ParticleCurve.MinSegment) ? ((t - k0.Time) / segment) : 0.0f;
		return ParticleCurve.Hermite(k0.Value, k0.TangentOut * segment, k1.Value,
			k1.TangentIn * segment, localT);
	}

	/// A sorted insert. Silently DROPS once full, which is the fixed cap being a cap rather
	/// than an error: an editor stops offering a ninth key.
	public bool AddKey(float time, float value, float tangentIn = 0.0f,
		float tangentOut = 0.0f) mut
	{
		if (KeyCount >= ParticleCurve.MaxKeys)
			return false;

		var index = KeyCount;
		while ((index > 0) && (Keys[index - 1].Time > time))
		{
			Keys[index] = Keys[index - 1];
			index--;
		}
		Keys[index] = .(time, value, tangentIn, tangentOut);
		KeyCount++;
		return true;
	}

	public static ParticleCurveFloat Constant(float value)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, value);
		return curve;
	}

	public static ParticleCurveFloat Linear(float from, float to)
	{
		var curve = ParticleCurveFloat();
		// The tangents are the straight line's own slope, which is what keeps it straight.
		curve.AddKey(0.0f, from, 0.0f, to - from);
		curve.AddKey(1.0f, to, to - from, 0.0f);
		return curve;
	}

	public static ParticleCurveFloat EaseIn(float from, float to)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, from, 0.0f, 0.0f);
		curve.AddKey(1.0f, to, 2.0f * (to - from), 0.0f);
		return curve;
	}

	public static ParticleCurveFloat EaseOut(float from, float to)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, from, 0.0f, 2.0f * (to - from));
		curve.AddKey(1.0f, to, 0.0f, 0.0f);
		return curve;
	}

	/// Holds, then falls to nothing over the tail. The shape almost every fade wants.
	public static ParticleCurveFloat FadeOut(float value, float fadeStart = 0.75f)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, value);
		curve.AddKey(fadeStart, value);
		curve.AddKey(1.0f, 0.0f);
		return curve;
	}

	/// Rises to a peak and falls away, which is what a puff of smoke does.
	public static ParticleCurveFloat PeakAt(float peakValue, float peakTime = 0.3f)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, 0.0f);
		curve.AddKey(peakTime, peakValue);
		curve.AddKey(1.0f, 0.0f);
		return curve;
	}

	/// COUNT BOUND: only the live keys are written, and a record claiming more than the cap
	/// is clamped rather than allowed to run off the fixed array.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "keyCount", ref KeyCount);
		KeyCount = Clamp(KeyCount, 0, (int32)ParticleCurve.MaxKeys);
		for (int32 i = 0; i < KeyCount; i++)
		{
			SerializeValue(ar, "time", ref Keys[i].Time);
			SerializeValue(ar, "value", ref Keys[i].Value);
			SerializeValue(ar, "tangentIn", ref Keys[i].TangentIn);
			SerializeValue(ar, "tangentOut", ref Keys[i].TangentOut);
		}
	}
}
