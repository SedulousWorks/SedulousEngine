using Sedulous.Core.Serialization;

namespace Sedulous.PropertyAnimation.Resource;

/// Registration for the property animation resource types.
///
/// Without it an instance writes its clip source fine and reads it back as null, which looks
/// like a missing asset rather than a missing call.
[SerializableRegistry]
static class PropertyAnimationResources
{
}
