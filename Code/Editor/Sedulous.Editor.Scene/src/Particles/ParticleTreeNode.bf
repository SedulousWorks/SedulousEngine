using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// One row of the particle effect tree.
class ParticleTreeNode
{
	public ParticleNodeKind Kind = .Effect;
	public int32 SystemIndex = -1;
	public int32 ModuleIndex = -1;
	public int32 Depth = 0;
	public String Label = new .() ~ delete _;
	/// Node ids.
	public List<int32> Children = new .() ~ delete _;

	public ParticleNodeRef Ref => .(Kind, SystemIndex, ModuleIndex);
}
