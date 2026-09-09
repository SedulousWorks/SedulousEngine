using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Net.Replication;

/// Tags an entity as replicated.
///
/// The server assigns the NetworkId and the client mirrors it. Persistent, because a designer
/// can mark an entity networked in the editor, so it rides SerializableComponentManager. Its
/// own fields are IDENTITY, not replicated state: none carries [Replicated], so the field
/// codec never touches them.
[SerializableComponent("net.Network")]
struct NetworkComponent : ISerializable
{
	public NetworkId Id = .();
	public NetworkAuthority Authority = .Server;
	/// The source prefab for a network spawn. Unset means a bare, non prefab networked entity.
	public Guid Prefab = .();

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "id", ref Id.Value);

		var authority = (uint8)Authority;
		SerializeValue(ar, "authority", ref authority);
		Authority = (NetworkAuthority)authority;

		Sedulous.Core.Serialization.Serialize(ar, ref Prefab);
	}
}
