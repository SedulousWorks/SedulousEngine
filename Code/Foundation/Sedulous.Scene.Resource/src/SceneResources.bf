using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// Registration for the scene resource types.
///
/// WHEN the serializable table is populated stays the application's business, as
/// everywhere else. Without this the documents write fine and read back as null: an
/// instance decodes its primary through the registry, by the type name it stored.
[SerializableRegistry]
static class SceneResources
{
}
