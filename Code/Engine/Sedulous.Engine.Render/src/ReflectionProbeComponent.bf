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
[SerializableComponent("reflection_probe")]
[DisplayName("Reflection Probe")]
[Category("Rendering")]
[Scriptable]
struct ReflectionProbeComponent : ISerializable
{
	/// World units, axis aligned.
	[Scriptable]
	public Float3 HalfExtents = .(5.0f, 5.0f, 5.0f);
	/// The soft falloff width, inward from the box edge.
	[Scriptable]
	[Range(0.0f, 10.0f, 0.1f)]
	[Description("Fade width at the probe volume's edge")]
	public float BlendDistance = 1.0f;
	[Scriptable]
	[Range(0.0f, 5.0f, 0.05f)]
	public float Intensity = 1.0f;
	/// The captured cube face size.
	[Scriptable]
	public uint32 Resolution = 128;
	/// The tie break when two volumes overlap. Higher wins.
	[Scriptable]
	public uint32 Priority = 0;
	[Scriptable]
	public ProbeUpdateMode Update = .Static;
	/// Box projects the reflection ray, rather than treating it as infinitely far away.
	[Scriptable]
	public bool Parallax = true;
	[Scriptable]
	public bool Enabled = true;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("halfExtents");
		Sedulous.Core.Serialization.Serialize(ar, ref HalfExtents);
		SerializeValue(ar, "blendDistance", ref BlendDistance);
		SerializeValue(ar, "intensity", ref Intensity);
		SerializeValue(ar, "resolution", ref Resolution);
		SerializeValue(ar, "priority", ref Priority);

		var update = (uint32)Update;
		SerializeValue(ar, "update", ref update);
		Update = (ProbeUpdateMode)update;

		SerializeValue(ar, "parallax", ref Parallax);
		SerializeValue(ar, "enabled", ref Enabled);
	}
}
