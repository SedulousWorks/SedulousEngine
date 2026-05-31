namespace Sedulous.Engine.Render;

using Sedulous.Engine.Core;
using Sedulous.Inspection;

/// How often a reflection probe recaptures the scene.
enum ReflectionProbeUpdateMode : uint8
{
	/// Capture once on load, never update.
	OnLoad,
	/// Re-capture every frame (expensive).
	EveryFrame,
	/// Re-capture when manually requested.
	Manual
}

/// Component for a reflection probe that captures the local environment
/// into a cubemap for image-based lighting.
[Component]
class ReflectionProbeComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		var mode = (uint8)UpdateMode;
		s.UInt8("UpdateMode", ref mode);
		if (s.IsReading) UpdateMode = (ReflectionProbeUpdateMode)mode;

		s.Float("InfluenceRadius", ref InfluenceRadius);

		var res = (uint32)CaptureResolution;
		s.UInt32("CaptureResolution", ref res);
		if (s.IsReading) CaptureResolution = (uint16)res;

		s.Float("NearClip", ref NearClip);
		s.Float("FarClip", ref FarClip);
		s.Float("Intensity", ref Intensity);
	}

	/// How often this probe recaptures.
	[Property(.Default, "Update Mode", "UpdateMode")]
	public ReflectionProbeUpdateMode UpdateMode = .OnLoad;

	/// Influence radius — fragments inside this sphere blend toward this probe's cubemap.
	[Property(.Default, "Influence Radius", "InfluenceRadius")]
	[Range(0.1f, 10000.0f)]
	public float InfluenceRadius = 10.0f;

	/// Cubemap face resolution (per face, in pixels). Common values: 64, 128, 256.
	[Property(.Default, "Capture Resolution", "CaptureResolution")]
	public uint16 CaptureResolution = 128;

	/// Near clip plane for probe capture camera.
	[Property(.Default, "Near Clip", "NearClip")]
	[Range(0.01f, 10.0f)]
	public float NearClip = 0.1f;

	/// Far clip plane for probe capture camera.
	[Property(.Default, "Far Clip", "FarClip")]
	[Range(1.0f, 100000.0f)]
	public float FarClip = 1000.0f;

	/// Intensity multiplier for the probe's contribution.
	[Property(.Default, "Intensity", "Intensity")]
	[Range(0.0f, 10.0f)]
	public float Intensity = 1.0f;
}
