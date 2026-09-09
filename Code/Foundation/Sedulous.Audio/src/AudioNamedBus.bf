using System;

namespace Sedulous.Audio;

/// A named CUSTOM bus: the freedom to shape the tree, on top of the fixed four.
///
/// The four remain the addressing model that components and saved data use; a custom bus is
/// addressed BY NAME instead.
class AudioNamedBus
{
	/// Unique within a layout, and case sensitive. Empty is ignored.
	public String Name = new .() ~ delete _;

	/// A fixed bus's name, case insensitively, or another custom bus's. Empty means Master.
	/// A cycle is rejected when the layout is cooked AND defused when it is applied, since
	/// authored data reaches the engine by paths a cook never saw.
	public String Parent = new .() ~ delete _;

	public AudioBusSettings Settings = new .() ~ delete _;
}
