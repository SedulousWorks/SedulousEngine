using System;
using System.Collections;

namespace Sedulous.Editor.Core;

/// What the closure pruning kept and dropped, with the roots and their reasons.
class PruningReport
{
	public bool Pruned = false;
	public List<ExportRoot> Roots = new .() ~ DeleteContainerAndItems!(_);
	/// Scenes plus cooked products in the closure, the size on disk.
	public int KeptCount = 0;
	/// The instance paths excluded: unreferenced, or unfinished.
	public List<String> Dropped = new .() ~ DeleteContainerAndItems!(_);

	public void CopyTo(PruningReport other)
	{
		other.Pruned = Pruned;
		ClearAndDeleteItems(other.Roots);
		for (let root in Roots)
			other.Roots.Add(root.Clone());
		other.KeptCount = KeptCount;
		ClearAndDeleteItems(other.Dropped);
		for (let dropped in Dropped)
			other.Dropped.Add(new String(dropped));
	}

	public void Format(String outText)
	{
		outText.Append("Export reachability pruning report\n");
		outText.Append("==================================\n");
		outText.AppendF("kept: {} instance(s) in the closure\n", KeptCount);
		outText.AppendF("roots: {}\n", Roots.Count);
		for (let root in Roots)
			outText.AppendF("  - {}  [{}]\n", root.Name.IsEmpty ? "(unresolved)" : StringView(root.Name), root.Reason.Name);
		outText.AppendF("dropped: {} instance(s)\n", Dropped.Count);
		for (let dropped in Dropped)
			outText.AppendF("  - {}\n", dropped);
	}
}
