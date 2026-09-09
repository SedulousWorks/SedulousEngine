using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A colour curve over normalised lifetime, which doubles as the colour gradient.
///
/// LINEAR between its keys rather than cubic, unlike the scalar curve: a cubic through
/// colours overshoots, and an overshoot in a colour channel is a colour that was never
/// authored.
struct ParticleCurveColor
{
	public CurveKeyColor[ParticleCurve.MaxKeys] Keys = .();
	public int32 KeyCount = 0;

	public this() {}

	public bool IsActive => KeyCount > 0;

	public Float4 Evaluate(float t)
	{
		// White rather than nothing, so an unset gradient leaves a particle its own colour.
		if (KeyCount <= 0)
			return .(1, 1, 1, 1);
		if (KeyCount == 1)
			return Keys[0].Color;
		if (t <= Keys[0].Time)
			return Keys[0].Color;
		if (t >= Keys[KeyCount - 1].Time)
			return Keys[KeyCount - 1].Color;

		var i = 0;
		while ((i < (KeyCount - 1)) && (t > Keys[i + 1].Time))
			i++;

		let k0 = Keys[i];
		let k1 = Keys[i + 1];
		let segment = k1.Time - k0.Time;
		let localT = (segment > ParticleCurve.MinSegment) ? ((t - k0.Time) / segment) : 0.0f;
		return k0.Color + (k1.Color - k0.Color) * localT;
	}

	public bool AddKey(float time, Float4 color) mut
	{
		if (KeyCount >= ParticleCurve.MaxKeys)
			return false;

		var index = KeyCount;
		while ((index > 0) && (Keys[index - 1].Time > time))
		{
			Keys[index] = Keys[index - 1];
			index--;
		}
		Keys[index] = .(time, color);
		KeyCount++;
		return true;
	}

	public static ParticleCurveColor Constant(Float4 color)
	{
		var curve = ParticleCurveColor();
		curve.AddKey(0.0f, color);
		return curve;
	}

	public static ParticleCurveColor Linear(Float4 from, Float4 to)
	{
		var curve = ParticleCurveColor();
		curve.AddKey(0.0f, from);
		curve.AddKey(1.0f, to);
		return curve;
	}

	/// The colour held, with only its ALPHA taken to nothing over the tail: a fade that keeps
	/// its hue rather than washing toward black.
	public static ParticleCurveColor FadeAlpha(Float4 color, float fadeStart = 0.75f)
	{
		var curve = ParticleCurveColor();
		curve.AddKey(0.0f, color);
		curve.AddKey(fadeStart, color);
		curve.AddKey(1.0f, .(color.X, color.Y, color.Z, 0.0f));
		return curve;
	}

	/// COUNT BOUND, see ParticleCurveFloat.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "keyCount", ref KeyCount);
		KeyCount = Clamp(KeyCount, 0, (int32)ParticleCurve.MaxKeys);
		for (int32 i = 0; i < KeyCount; i++)
		{
			SerializeValue(ar, "time", ref Keys[i].Time);
			SerializeValue(ar, "color", ref Keys[i].Color);
		}
	}
}
