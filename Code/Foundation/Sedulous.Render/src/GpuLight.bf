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
	/// Reserved, and part of the layout: the shader reads four whole vectors.
	public float Pad = 0.0f;

	public this() {}

	/// What the shader's declaration says this is.
	public const int SizeInBytes = 64;
}
