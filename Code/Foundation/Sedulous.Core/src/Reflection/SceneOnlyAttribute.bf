using System;

namespace Sedulous.Core;

/// A settings block's member that belongs to the SCENE even while the block takes its values
/// from a shared profile: the block's source and its profile reference.
///
/// An editor that edits the profile in place of the scene's own values leaves these on the
/// scene, because a profile has no source of its own.
[AttributeUsage(.Field | .Property,
	.NotInherited | .ReflectAttribute | .DisallowAllowMultiple)]
struct SceneOnlyAttribute : Attribute
{
}
