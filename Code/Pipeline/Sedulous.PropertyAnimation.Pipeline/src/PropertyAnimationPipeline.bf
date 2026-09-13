using Sedulous.Core.Serialization;

namespace Sedulous.PropertyAnimation.Pipeline;

/// Registration for the property animation authoring types.
///
/// Without it an instance writes its asset fine and reads it back as null, which looks like a
/// missing file rather than a missing call.
[SerializableRegistry]
static class PropertyAnimationPipeline
{
}
