using Sedulous.Core;

namespace Sedulous.Engine.Audio;

/// Which of a source's two references plays.
///
/// An explicit discriminant rather than "the cue wins when it is set": it declutters an
/// inspector, only the relevant reference showing, and it says at runtime which was intended
/// when both happen to be bound.
[Scriptable(.AllPublic)]
enum AudioSourceType : uint8
{
	Clip,
	Cue
}
