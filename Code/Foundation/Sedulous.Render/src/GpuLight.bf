using System;
using Sedulous.Core;

namespace Sedulous.Render;

/// One light, packed exactly as the shader's storage buffer reads it.
///
/// A shading INPUT rather than a drawable: extracted into the scene's light list, uploaded,
/// and consumed by the forward shading loop. Sixty four bytes, four vectors, and the padding
/// is part of the layout rather than an accident of it.
[CRepr]
struct GpuLight
{
	public Float3 PositionWS = .(0, 0, 0);
	/// Packed beside the position, as its fourth component.
	public float Range = 0.0f;

	public Float3 Color = .(1, 1, 1);
	public float Intensity = 1.0f;

	public Float3 DirectionWS = .(0, -1, 0);
	/// Nought directional, one point, two spot.
	public float Type = 0.0f;

	/// The spot cone's cosines.
	public float InnerCos = 1.0f;
	public float OuterCos = 1.0f;

	/// Minus one casts no shadow; anything else selects an entry in the shadow data.
	public float ShadowIndex = -1.0f;
	/// How dark the light's shadow gets: one is full, nought none (the shader lerps toward
	/// lit).
	public float ShadowStrength = 1.0f;

	public this() {}

	/// The share of this light's intensity that reaches `point`, before any shadow: the
	/// forward shader's range falloff and spot cone (forward.ps.hlsl Attenuation and
	/// SpotAttenuation, kept the same), on the CPU, for a game asking how lit a place is. One
	/// for a directional light.
	public float FalloffAt(Float3 point)
	{
		if (Type < 0.5f)
			return 1.0f;
		let toLight = PositionWS - point;
		let distance = Length(toLight);
		var falloff = 1.0f;
		if (Range > 0.0f)
		{
			let d = distance / Range;
			let d2 = d * d;
			let window = Math.Clamp(1.0f - d2 * d2, 0.0f, 1.0f);
			falloff = (window * window) / (distance * distance + 1e-4f);
		}
		if (Type > 1.5f)
		{
			let l = toLight / Math.Max(distance, 1e-4f);
			let cosAngle = -Dot(l, DirectionWS);
			falloff *= Math.Clamp((cosAngle - OuterCos) / (InnerCos - OuterCos + 1e-4f), 0.0f, 1.0f);
		}
		return falloff;
	}

	/// What the shader's declaration says this is.
	public const int SizeInBytes = 64;
}
