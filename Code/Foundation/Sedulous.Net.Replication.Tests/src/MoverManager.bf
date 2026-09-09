using Sedulous.Scene;

namespace Sedulous.Net.Replication.Tests;

/// A serializable pool, so a Mover can live in a scene and carry the wire tag "test.Mover".
class MoverManager : SerializableComponentManager<Mover>
{
}
