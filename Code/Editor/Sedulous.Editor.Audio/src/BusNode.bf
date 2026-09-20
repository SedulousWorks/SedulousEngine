using System;
using System.Collections;

namespace Sedulous.Editor.Audio;

/// One row of the bus tree: a fixed bus by index, or a custom slot.
class BusNode
{
	public bool Fixed = true;
	/// 0 Master, 1 Effects, 2 Music, 3 UI.
	public int32 FixedIndex = 0;
	public int32 SlotIndex = -1;
	public int32 Depth = 0;
	/// Node ids.
	public List<int32> Children = new .() ~ delete _;
}
