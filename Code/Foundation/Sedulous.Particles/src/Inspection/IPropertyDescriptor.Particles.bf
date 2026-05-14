namespace Sedulous.Inspection;

using Sedulous.Particles;
using System;

/// Particle-side extension of IPropertyDescriptor: adds descriptor methods
/// for the awkward types the codegen will encounter on particle initializers
/// and behaviors. Lives in Sedulous.Particles so the descriptor interface in
/// Sedulous.Inspection doesn't need to know about particle types - the
/// extension mechanism stitches them together at compile time.
///
/// Any IPropertyDescriptor implementation (e.g. the editor's
/// EditorPropertyGridDescriptor) must also implement these extension methods
/// to be usable with comptime-generated DescribeProperties on particle types.
extension IPropertyDescriptor
{
	/// RangeFloat field (Min/Max float pair).
	void RangeFloat(StringView name, RangeFloat* ptr);

	/// RangeVector2 field (Min/Max Vector2 pair).
	void RangeVector2(StringView name, RangeVector2* ptr);

	/// RangeColor field (Min/Max Vector4 pair; HDR colors allowed).
	void RangeColor(StringView name, RangeColor* ptr);

	/// ParticleCurveFloat field (up to 8 Hermite-interpolated keyframes).
	void CurveFloat(StringView name, ParticleCurveFloat* ptr);

	/// ParticleCurveColor field (up to 8 linearly-interpolated color keyframes).
	void CurveColor(StringView name, ParticleCurveColor* ptr);

	/// ParticleCurveVector2 field (up to 8 per-component Hermite-interpolated keyframes).
	void CurveVector2(StringView name, ParticleCurveVector2* ptr);

	/// EmissionShape field (Type enum + shape parameters).
	void EmissionShape(StringView name, EmissionShape* ptr);
}
