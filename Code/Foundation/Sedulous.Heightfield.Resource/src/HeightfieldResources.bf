using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Heightfield.Resource;

/// Registration for the heightfield resource types.
///
/// Without it an instance writes its metadata fine and reads it back as null, which looks
/// like a missing asset rather than a missing call.
[SerializableRegistry]
static class HeightfieldResources
{
	/// The manager does not take ownership, so the caller keeps the factory alive for as
	/// long as it keeps the manager.
	public static void AddFactories(ResourceManager manager, HeightfieldFactory heightfields)
	{
		manager.AddFactory(heightfields);
	}
}
