using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A colour curve over normalised lifetime: a gradient of Core's, sampled by
/// EvaluateGradient, its colour stops and its alpha stops apart, blended in a chosen space.
///
/// Its colours are authored sRGB, decoded to linear only when the particle is drawn. The
/// default blend is the sRGB values straight, which is what the curve always did.
[Scriptable]
struct ParticleCurveColor
{
	public GradientColorStop[ParticleCurve.MaxKeys] Colors = .();
	[Scriptable]
	public int32 ColorCount = 0;
	public GradientAlphaStop[ParticleCurve.MaxKeys] Alphas = .();
	[Scriptable]
	public int32 AlphaCount = 0;
	[Scriptable]
	public GradientInterpolation Interpolation = .Srgb;

	public this() {}

	public bool IsActive => (ColorCount > 0) || (AlphaCount > 0);

	/// The sRGB colour and alpha at t: white and opaque where it has no stops, so an unset
	/// gradient leaves a particle its own colour.
	public Float4 Evaluate(float t)
	{
		// Copies: a struct method may not take its own fields' addresses, and eight stops are cheap.
		var colors = Colors;
		var alphas = Alphas;
		let c = EvaluateGradient(.(&colors[0], Clamp(ColorCount, 0, (int32)ParticleCurve.MaxKeys)),
			.(&alphas[0], Clamp(AlphaCount, 0, (int32)ParticleCurve.MaxKeys)), Interpolation, t);
		return .(c.R, c.G, c.B, c.A);
	}

	/// Sorted inserts, refused once full.
	public bool AddColor(float time, Color color) mut
	{
		if (ColorCount >= ParticleCurve.MaxKeys)
			return false;
		var index = ColorCount;
		while ((index > 0) && (Colors[index - 1].Time > time))
		{
			Colors[index] = Colors[index - 1];
			index--;
		}
		Colors[index] = .(time, color);
		ColorCount++;
		return true;
	}

	public bool AddAlpha(float time, float alpha) mut
	{
		if (AlphaCount >= ParticleCurve.MaxKeys)
			return false;
		var index = AlphaCount;
		while ((index > 0) && (Alphas[index - 1].Time > time))
		{
			Alphas[index] = Alphas[index - 1];
			index--;
		}
		Alphas[index] = .(time, alpha);
		AlphaCount++;
		return true;
	}

	/// A colour stop and an alpha stop at one time, from an sRGB rgba.
	public bool AddKey(float time, Float4 color) mut
	{
		let added = AddColor(time, .(color.X, color.Y, color.Z));
		return AddAlpha(time, color.W) && added;
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
		curve.AddColor(0.0f, .(color.X, color.Y, color.Z));
		curve.AddAlpha(0.0f, color.W);
		curve.AddAlpha(fadeStart, color.W);
		curve.AddAlpha(1.0f, 0.0f);
		return curve;
	}

	/// In an object of its own and COUNT BOUND, see ParticleCurveFloat.
	///
	/// LEGACY (removed once the samples are re-saved): text written before gradients has the
	/// curve's fields loose in the module's object, a keyCount of an sRGB rgba each and no
	/// interpolation; each becomes a colour stop and an alpha stop at its time.
	public void Serialize(ISerializer ar) mut
	{
		if ((ar.Mode == .Read) && ar.HasKey("keyCount") && !ar.HasKey("interpolation"))
		{
			ReadLegacy(ar);
			return;
		}

		ar.BeginObject();
		SerializeValue(ar, "interpolation", ref Interpolation);
		SerializeValue(ar, "colorCount", ref ColorCount);
		ColorCount = Clamp(ColorCount, 0, (int32)ParticleCurve.MaxKeys);
		for (int32 i = 0; i < ColorCount; i++)
		{
			ar.Key("color");
			ar.BeginObject();
			SerializeValue(ar, "time", ref Colors[i].Time);
			SerializeValue(ar, "color", ref Colors[i].Color);
			ar.EndObject();
		}
		SerializeValue(ar, "alphaCount", ref AlphaCount);
		AlphaCount = Clamp(AlphaCount, 0, (int32)ParticleCurve.MaxKeys);
		for (int32 i = 0; i < AlphaCount; i++)
		{
			ar.Key("alpha");
			ar.BeginObject();
			SerializeValue(ar, "time", ref Alphas[i].Time);
			SerializeValue(ar, "alpha", ref Alphas[i].Alpha);
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
			var color = Float4(1, 1, 1, 1);
			SerializeValue(ar, "time", ref time);
			SerializeValue(ar, "color", ref color);
			AddKey(time, color);
		}
	}
}
