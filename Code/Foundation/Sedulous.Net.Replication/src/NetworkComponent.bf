using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

using Sedulous.Core;

namespace Sedulous.Net.Replication;

/// Tags an entity as replicated.
///
/// The server assigns the NetworkId and the client mirrors it. Persistent, because a designer
/// can mark an entity networked in the editor, so it rides SerializableComponentManager. Its
/// own fields are IDENTITY, not replicated state: none carries [Replicated], so the field
/// codec never touches them.
///
/// A script READS the identity and writes nothing: Authority is the gate a behaviour needs
/// (the owning side drives, the rest interpolate) and Id is for logging. Replication owns
/// both, and neither is itself replicated, so a script assigning Authority would desync the
/// two sides silently. Prefab is replication's bookkeeping, off the surface.
[SerializableComponent("net.Network")]
[Scriptable]
struct NetworkComponent : ISerializable
{
	[Scriptable, ReadOnly]
	public NetworkId Id = .();
	[Scriptable, ReadOnly]
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
