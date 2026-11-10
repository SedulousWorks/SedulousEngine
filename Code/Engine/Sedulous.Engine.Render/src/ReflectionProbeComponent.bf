using System;
using Sedulous.Scene;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Render;

namespace Sedulous.Engine.Render;

/// A local reflection probe: it captures the scene into a cubemap from its entity's position
/// and gives parallax corrected specular reflections to surfaces inside its box.
///
/// The box is BOTH the influence volume and the parallax proxy. The blend distance softens
/// the influence inward from its edge, so two overlapping probes meet without a seam.
///
/// Every probe captures at the probe system's one size (they share one cube array, whose slices
/// cannot differ), so a probe has no resolution of its own. Version 2 dropped it; a version 1
/// record's is read and discarded.
[SerializableComponent("reflection_probe", 2, 1)]
[DisplayName("Reflection Probe")]
[Category("Rendering")]
[Description("Captures the scene around the entity into a cubemap that gives reflections to surfaces in its box.")]
struct ReflectionProbeComponent : ISerializable
{
	/// World units, axis aligned.
	public Float3 HalfExtents = .(5.0f, 5.0f, 5.0f);
	/// The soft falloff width, inward from the box edge.
	[Range(0.0f, 10.0f, 0.1f)]
	[Description("Fade width at the probe volume's edge")]
	public float BlendDistance = 1.0f;
	[Range(0.0f, 5.0f, 0.05f)]
	public float Intensity = 1.0f;
	/// The tie break when two volumes overlap. Higher wins.
	public uint32 Priority = 0;
	public ProbeUpdateMode Update = .Static;
	/// Box projects the reflection ray, rather than treating it as infinitely far away.
	public bool Parallax = true;
	public bool Enabled = true;
	/// Runtime: the capture requests made so far (never serialized). A Manual probe captures
	/// only when asked; any probe recaptures once when asked (after its room changed).
	[Hidden]
	public uint32 CaptureRequests = 0;

	public this() {}

	/// Asks for one capture: a Manual probe's only way to capture again, and a Static one's
	/// after what it reflects has changed.
	public void Capture() mut => CaptureRequests++;

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("halfExtents");
		Sedulous.Core.Serialization.Serialize(ar, ref HalfExtents);
		SerializeValue(ar, "blendDistance", ref BlendDistance);
		SerializeValue(ar, "intensity", ref Intensity);
		if ((ar.Mode == .Read) && (ar.Version < 2))
		{
			// A version 1 probe carried a per-probe resolution the renderer never applied: read
			// past it.
			uint32 resolution = 0;
			SerializeValue(ar, "resolution", ref resolution);
		}
		SerializeValue(ar, "priority", ref Priority);

		var update = (uint32)Update;
		SerializeValue(ar, "update", ref update);
		Update = (ProbeUpdateMode)update;

		SerializeValue(ar, "parallax", ref Parallax);
		SerializeValue(ar, "enabled", ref Enabled);
	}
}
