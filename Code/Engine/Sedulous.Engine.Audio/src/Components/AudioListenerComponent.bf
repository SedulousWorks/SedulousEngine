namespace Sedulous.Engine.Audio;

using Sedulous.Scenes;

/// Component marking an entity as the 3D audio listener.
/// Position and orientation are synced from the entity's world transform.
/// Only one listener should be active at a time — if multiple exist,
/// the first active one is used.
class AudioListenerComponent : Component
{
	/// Whether this is the active listener. Only one should be true at a time.
	public bool IsActiveListener = true;
}
