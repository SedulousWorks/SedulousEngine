using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// One entity of a captured subtree, parents before children.
///
/// `Id` is the ORIGINAL guid: a paste mints fresh ids and uses it only to relink parents
/// within the records, while a destroy's undo recreates the entity under it. `Parent` is
/// nil for the subtree root in a clipboard capture, and the actual parent, which may lie
/// outside the subtree, in a destroy record.
class SubtreeRecord
{
	public Guid Id = .();
	public Guid Parent = .();
	public String Name = new .() ~ delete _;
	public Transform Local = .();
	public bool Active = true;
	public List<SubtreeComponentRecord> Components = new .() ~ DeleteContainerAndItems!(_);
}
