namespace Sedulous.Engine.Audio;

using Sedulous.Engine.Core;
using Sedulous.Inspection;

/// Component marking an entity as the 3D audio listener.
/// Position and orientation are synced from the entity's world transform.
/// Only one listener should be active at a time - if multiple exist,
/// the first active one is used.
[Component]
class AudioListenerComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.Bool("IsActiveListener", ref IsActiveListener);
	}

	/// Whether this is the active listener. Only one should be true at a time.
	[Property(.Default, "Is Active Listener", "IsActiveListener")]
	public bool IsActiveListener = true;
}
