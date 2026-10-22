using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A scalar curve over normalised lifetime: Core's CurveKeys, sampled by EvaluateCurve, so a
/// key can be constant, linear or cubic and keeps a tangent mode.
///
/// NOT ACTIVE with no keys, which is what gates the behaviours that read one: an unset curve
/// is a behaviour that does nothing rather than a behaviour that drives everything to zero.
[Scriptable]
struct ParticleCurveFloat
{
	public CurveKey[ParticleCurve.MaxKeys] Keys = .();
	[Scriptable]
	public int32 KeyCount = 0;

	public this() {}

	public bool IsActive => KeyCount > 0;

	/// CLAMPED at both ends, as EvaluateCurve is: a lifetime outside the authored range holds
	/// rather than extrapolating off the curve.
	public float Evaluate(float t)
	{
		// A copy: a struct method may not take its own field's address, and eight keys are cheap.
		var keys = Keys;
		return EvaluateCurve(.(&keys[0], Clamp(KeyCount, 0, (int32)ParticleCurve.MaxKeys)), t);
	}

	/// A sorted insert. Refused once full, which is the fixed cap being a cap rather than an
	/// error: an editor stops offering a ninth key.
	public bool AddKey(CurveKey key) mut
	{
		if (KeyCount >= ParticleCurve.MaxKeys)
			return false;

		var index = KeyCount;
		while ((index > 0) && (Keys[index - 1].Time > key.Time))
		{
			Keys[index] = Keys[index - 1];
			index--;
		}
		Keys[index] = key;
		KeyCount++;
		return true;
	}

	/// A key as the particles' curves always made one: cubic, its tangents as given (flat by
	/// default, so a run of them eases from key to key); another interpolation when asked.
	public bool AddKey(float time, float value, float tangentIn = 0.0f, float tangentOut = 0.0f,
		CurveKeyInterpolation interpolation = .Cubic, CurveTangentMode mode = .Broken) mut
	{
		var key = CurveKey(time, value, interpolation, tangentIn, tangentOut);
		key.TangentMode = mode;
		return AddKey(key);
	}

	public static ParticleCurveFloat Constant(float value)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, value);
		return curve;
	}

	/// Straight from one to the other.
	public static ParticleCurveFloat Linear(float from, float to)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, from, 0.0f, 0.0f, .Linear);
		curve.AddKey(1.0f, to, 0.0f, 0.0f, .Linear);
		return curve;
	}

	/// From one to the other, easing out of the first and into the second: flat at both ends,
	/// a smoothstep.
	public static ParticleCurveFloat Ease(float from, float to)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, from, 0.0f, 0.0f, .Cubic, .Flat);
		curve.AddKey(1.0f, to, 0.0f, 0.0f, .Cubic, .Flat);
		return curve;
	}

	/// Slow out of the first, fast into the second.
	public static ParticleCurveFloat EaseIn(float from, float to)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, from, 0.0f, 0.0f, .Cubic, .Flat);
		curve.AddKey(1.0f, to, 2.0f * (to - from), 0.0f);
		return curve;
	}

	/// Fast out of the first, slow into the second.
	public static ParticleCurveFloat EaseOut(float from, float to)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, from, 0.0f, 2.0f * (to - from));
		curve.AddKey(1.0f, to, 0.0f, 0.0f, .Cubic, .Flat);
		return curve;
	}

	/// Holds, then eases to nothing over the tail. The shape almost every fade wants.
	public static ParticleCurveFloat FadeOut(float value, float fadeStart = 0.75f)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, value, 0.0f, 0.0f, .Cubic, .Flat);
		curve.AddKey(fadeStart, value, 0.0f, 0.0f, .Cubic, .Flat);
		curve.AddKey(1.0f, 0.0f, 0.0f, 0.0f, .Cubic, .Flat);
		return curve;
	}

	/// Eases up to a peak and back down to nothing, which is what a puff of smoke does.
	public static ParticleCurveFloat PeakAt(float peakValue, float peakTime = 0.3f)
	{
		var curve = ParticleCurveFloat();
		curve.AddKey(0.0f, 0.0f, 0.0f, 0.0f, .Cubic, .Flat);
		curve.AddKey(peakTime, peakValue, 0.0f, 0.0f, .Cubic, .Flat);
		curve.AddKey(1.0f, 0.0f, 0.0f, 0.0f, .Cubic, .Flat);
		return curve;
	}

	/// In an object of its own, so two curves of one module keep apart, and COUNT BOUND: only
	/// the live keys are written, each in an object, and a record claiming more than the cap
	/// is clamped rather than allowed to run off the fixed array.
	///
	/// LEGACY (removed once the samples are re-saved): text written before Core's keys has the
	/// curve's fields loose in the module's object, a keyCount and no key objects, and each key
	/// cubic with its tangents as stored. Only text can be old: a binary reader says it has
	/// every key, and a binary product is cooked again (the builder's version moved).
	public void Serialize(ISerializer ar) mut
	{
		if ((ar.Mode == .Read) && ar.HasKey("keyCount") && !ar.HasKey("key"))
		{
			ReadLegacy(ar);
			return;
		}

		ar.BeginObject();
		SerializeValue(ar, "keyCount", ref KeyCount);
		KeyCount = Clamp(KeyCount, 0, (int32)ParticleCurve.MaxKeys);
		for (int32 i = 0; i < KeyCount; i++)
		{
			ar.Key("key");
			ar.BeginObject();
			SerializeValue(ar, "time", ref Keys[i].Time);
			SerializeValue(ar, "value", ref Keys[i].Value);
			SerializeValue(ar, "tangentIn", ref Keys[i].TangentIn);
			SerializeValue(ar, "tangentOut", ref Keys[i].TangentOut);
			SerializeValue(ar, "interpolation", ref Keys[i].Interpolation);
			SerializeValue(ar, "tangentMode", ref Keys[i].TangentMode);
			ar.EndObject();
		}
		ar.EndObject();
	}

	private void ReadLegacy(ISerializer ar) mut
	{
		int32 count = 0;
		SerializeValue(ar, "keyCount", ref count);
		this = .();
		for (int32 i = 0; i < Clamp(count, 0, (int32)ParticleCurve.MaxKeys); i++)
		{
			var time = 0.0f;
			var value = 0.0f;
			var tangentIn = 0.0f;
			var tangentOut = 0.0f;
			SerializeValue(ar, "time", ref time);
			SerializeValue(ar, "value", ref value);
			SerializeValue(ar, "tangentIn", ref tangentIn);
			SerializeValue(ar, "tangentOut", ref tangentOut);
			AddKey(time, value, tangentIn, tangentOut);
		}
	}
}
