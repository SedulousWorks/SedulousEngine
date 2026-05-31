namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Renderer;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Component for an image-based lighting reflection probe.
///
/// The entity's world transform defines the probe's capture position. The
/// probe captures the surrounding scene to a cubemap (managed by the
/// renderer's IBL system), prefilters it for split-sum specular, and
/// projects it to SH9 for diffuse irradiance. Fragments inside the
/// influence bounds blend the probe's contribution into their indirect
/// lighting.
[Component]
class ReflectionProbeComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.Float("InfluenceRadius", ref InfluenceRadius);

		s.BeginObject("BoxMin");
		s.Float("X", ref LocalBoxMin.X);
		s.Float("Y", ref LocalBoxMin.Y);
		s.Float("Z", ref LocalBoxMin.Z);
		s.EndObject();

		s.BeginObject("BoxMax");
		s.Float("X", ref LocalBoxMax.X);
		s.Float("Y", ref LocalBoxMax.Y);
		s.Float("Z", ref LocalBoxMax.Z);
		s.EndObject();

		s.Float("BlendEdge", ref BlendEdge);
		s.UInt32("LayerMask", ref LayerMask);
	}

	/// Sphere influence radius. Fragments outside this distance from the
	/// probe's capture position get zero contribution from this probe.
	[Property(.Default, "Influence Radius", "InfluenceRadius")]
	[Range(0.5f, 500.0f)]
	public float InfluenceRadius = 10.0f;

	/// Min corner of the box that defines the "full influence" region in
	/// the entity's local space. Inside this box the probe is at full
	/// weight; outside, weight falls off through BlendEdge to zero at
	/// InfluenceRadius.
	[Property(.Default, "Local Box Min", "LocalBoxMin")]
	public Vector3 LocalBoxMin = .(-5, -5, -5);

	/// Max corner of the local-space influence box.
	[Property(.Default, "Local Box Max", "LocalBoxMax")]
	public Vector3 LocalBoxMax = .(5, 5, 5);

	/// World-space falloff distance from the box surface to zero
	/// contribution at the influence radius. Larger values give smoother
	/// transitions between probes at the cost of less localized lighting.
	[Property(.Default, "Blend Edge", "BlendEdge")]
	[Range(0.0f, 50.0f)]
	public float BlendEdge = 1.0f;

	/// Render layer mask. Probes only contribute to fragments whose layer
	/// matches.
	[Property(.Default, "Layer Mask", "LayerMask")]
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Stable slot index assigned by ReflectionProbeManager. Determines the
	/// probe's slice in the prefiltered cubemap array and its SH9 entries.
	/// -1 = unassigned (manager ran out of probe slots).
	public int32 ArraySlot = -1;
}
