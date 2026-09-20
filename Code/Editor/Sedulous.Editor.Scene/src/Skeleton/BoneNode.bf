using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// One bone in a skeleton tree snapshot; the node id is the bone index.
class BoneNode
{
	public int32 BoneIndex = -1;
	public int32 Depth = 0;
	/// Node ids.
	public List<int32> Children = new .() ~ delete _;
}
