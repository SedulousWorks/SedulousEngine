using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// One serializable component of a captured entity: its manager's stable id and the bytes
/// its manager wrote, read back by whichever manager answers to that id.
class SubtreeComponentRecord
{
	public String TypeId = new .() ~ delete _;
	public List<uint8> Blob = new .() ~ delete _;
}
