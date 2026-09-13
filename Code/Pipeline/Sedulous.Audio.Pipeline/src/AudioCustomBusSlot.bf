using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Audio.Pipeline;

/// A named bus the author added, in one of a fixed bank of slots.
///
/// FIXED slots rather than a list, for the same reason the fields above are flat: the generic
/// property page edits them without an array editor. An empty name disables the slot.
[Serializable]
class AudioCustomBusSlot
{
	/// Empty means the slot is unused.
	public String Name = new .() ~ delete _;

	/// One of the fixed bus names, matched without case, or another slot's name. Empty means
	/// the master bus.
	public String Parent = new .() ~ delete _;

	public AudioBusAuthoring Bus = new .() ~ delete _;
}
