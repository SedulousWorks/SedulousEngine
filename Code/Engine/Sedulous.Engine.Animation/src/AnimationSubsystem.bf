using Sedulous.Runtime;

namespace Sedulous.Engine.Animation;

/// The Context level animation subsystem.
///
/// It does NO per frame work of its own: the managers are scene systems, and the scene's own
/// tick drives them. Attaching a component is all an application needs, which is what this
/// subsystem's existence buys.
class AnimationSubsystem : Subsystem
{
}
