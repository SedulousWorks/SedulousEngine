using System;
using System.Collections;
using Sedulous.Script;

namespace Sedulous.Editor.Script;

/// The API browser's node table: types sorted by name, members sorted under each, a filter
/// keeping a type with everything under it or just the members that match.
class ScriptApiTree
{
	public List<ScriptApiTreeNode> Nodes = new .() ~ DeleteContainerAndItems!(_);
	/// Depth zero node indices, in display order.
	public List<int32> Roots = new .() ~ delete _;

	public bool InRange(int32 nodeId) => (nodeId >= 0) && (nodeId < Nodes.Count);

	/// Rebuilds from `types`; `isEditorOnly` (may be null) marks a type's label.
	public void Build(List<ScriptApiType> types, StringView filter, delegate bool(ScriptApiType) isEditorOnly = null)
	{
		ClearAndDeleteItems!(Nodes);
		Roots.Clear();

		let typeOrder = scope List<int>();
		for (int i < types.Count)
			typeOrder.Add(i);
		typeOrder.Sort(scope (a, b) => StringView.Compare(types[a].ScriptName, types[b].ScriptName));

		let memberOrder = scope List<int>();
		for (let typeIndex in typeOrder)
		{
			let type = types[typeIndex];
			let typeMatches = ContainsIgnoreCase(type.ScriptName, filter);
			memberOrder.Clear();
			for (int i < type.Members.Count)
			{
				if (typeMatches || ContainsIgnoreCase(type.Members[i].Name, filter))
					memberOrder.Add(i);
			}
			if (!typeMatches && memberOrder.IsEmpty)
				continue; // neither the type nor any member survived the filter
			memberOrder.Sort(scope (a, b) => StringView.Compare(type.Members[a].Name, type.Members[b].Name));

			let typeNode = new ScriptApiTreeNode();
			typeNode.Label.Set(type.ScriptName);
			if ((isEditorOnly != null) && isEditorOnly(type))
				typeNode.Label.Append(" [editor]");
			typeNode.InsertText.Set(type.ScriptName);
			typeNode.Depth = 0;
			let typeNodeIndex = (int32)Nodes.Count;
			Nodes.Add(typeNode);
			Roots.Add(typeNodeIndex);
			for (let memberIndex in memberOrder)
			{
				let member = type.Members[memberIndex];
				let memberNode = new ScriptApiTreeNode();
				memberNode.Label.Set(member.Signature.IsEmpty ? StringView(member.Name) : StringView(member.Signature));
				memberNode.InsertText.Set(member.Name);
				memberNode.Depth = 1;
				let memberNodeIndex = (int32)Nodes.Count;
				Nodes.Add(memberNode);
				typeNode.Children.Add(memberNodeIndex);
			}
		}
	}

	/// An empty needle matches everything.
	public static bool ContainsIgnoreCase(StringView haystack, StringView needle)
	{
		if (needle.IsEmpty)
			return true;
		return haystack.IndexOf(needle, true) >= 0;
	}
}
