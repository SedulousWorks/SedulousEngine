using Sedulous.Core.Serialization;
using Sedulous.Scene;

using Sedulous.Core;

namespace Sedulous.Engine.Audio;

/// A sphere of environmental reverb, which follows the LISTENER rather than any source.
///
/// While the scene's listener is inside, the scene's effects tier reverberates: the wet
/// signal fades in across the edge band, and the WETTEST zone containing the listener wins.
[SerializableComponent("audio.ReverbZone")]
[DisplayName("Reverb Zone")]
[Category("Audio")]
[Scriptable]
struct AudioReverbZoneComponent : ISerializable
{
	[Scriptable]
	public float Radius = 8.0f;
	/// The fraction of the radius over which the wet signal fades from nothing to full.
	[Scriptable]
	public float EdgeFade = 0.25f;
	[Scriptable]
	public float RoomSize = 0.6f;
	[Scriptable]
	public float Damping = 0.4f;
	[Scriptable]
	public float WetLevel = 0.5f;
	[Scriptable]
	public bool Enabled = true;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "edgeFade", ref EdgeFade);
		SerializeValue(ar, "roomSize", ref RoomSize);
		SerializeValue(ar, "damping", ref Damping);
		SerializeValue(ar, "wetLevel", ref WetLevel);
		SerializeValue(ar, "enabled", ref Enabled);
	}
}
