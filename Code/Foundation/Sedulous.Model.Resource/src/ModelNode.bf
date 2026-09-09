using System;
using Sedulous.Core;

namespace Sedulous.Model.Resource;

/// One node of an imported hierarchy: where it sits, and what it draws.
class ModelNode
{
	public String Name = new .() ~ delete _;
	/// Minus one is a root.
	public int32 ParentIndex = -1;
	public Transform LocalTransform = .();
	/// An index into the model's mesh list. Minus one is a node that draws nothing, which is
	/// most of them: a hierarchy carries pivots and attachment points as well as geometry.
	public int32 MeshIndex = -1;
}
