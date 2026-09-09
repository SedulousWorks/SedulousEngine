using Sedulous.Core;

namespace Sedulous.Render;

/// A reflection probe, as extraction leaves it.
///
/// The probe system captures the scene into a cubemap from the centre and prefilters it; the
/// forward shading then samples it with a PARALLAX CORRECTION against the box, which is what
/// makes a reflection land on the wall it belongs to rather than at infinity.
struct ReflectionProbe
{
	/// A stable per entity tag, so the system can keep this probe on the same GPU slot from
	/// one frame to the next.
	public uint64 Key = 0;

	public Float3 Center = .(0, 0, 0);
	/// The box's half extents, which are both its influence and the proxy the parallax
	/// correction projects against. World axis aligned rather than oriented.
	public Float3 HalfExtents = .(5, 5, 5);
	/// How far inward from the box's edge the influence softens, so two overlapping probes
	/// blend rather than meeting at a seam.
	public float BlendDistance = 1.0f;
	public float Intensity = 1.0f;

	/// The captured face size.
	public uint32 Resolution = 128;
	/// Breaks the tie where two probes overlap: higher wins.
	public uint32 Priority = 0;

	public ProbeUpdateMode Update = .Static;
	/// Whether to box project the reflection ray, rather than treating it as infinitely far.
	public bool Parallax = true;

	public this() {}
}
