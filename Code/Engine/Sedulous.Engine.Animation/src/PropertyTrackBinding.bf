using System;
using Sedulous.PropertyAnimation;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// One track's runtime binding: the target's manager, found by type name and stable for the
/// scene, and the resolved property chain, which is static metadata.
///
/// The component INSTANCE is never cached here. It is re-derived through the manager on every
/// write, because the pool swaps its last component into a hole on removal and an address
/// taken once would then be writing into somebody else's component.
///
/// A failed resolve DISABLES the track, warned once: the clip keeps playing its other tracks
/// rather than failing whole.
class PropertyTrackBinding
{
	/// BORROWED, and null for the built in transform target.
	public ComponentManagerBase Manager = null;
	public PropertyBinding Binding = new .() ~ delete _;
	public bool Disabled = false;
	/// Targets the entity's scene transform, which has no component manager.
	public bool IsTransform = false;
}
