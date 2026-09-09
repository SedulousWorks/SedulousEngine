using Sedulous.Core;

namespace Sedulous.Animation;

/// A bone's local transform, which is Core's own: position, rotation and scale.
///
/// An alias rather than a copy, because the lerp and the matrix are already there and a
/// second spelling of the same three fields would be a second place to fix.
typealias BoneTransform = Transform;
