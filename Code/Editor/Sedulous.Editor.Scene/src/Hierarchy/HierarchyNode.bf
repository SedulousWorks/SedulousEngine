using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// One entity in the hierarchy's pre-order snapshot; the node id is its index.
class HierarchyNode
{
	public Guid Id = .();
	public String Name = new .() ~ delete _;
	public int32 Depth = 0;
	public List<int32> Children = new .() ~ delete _;
}
