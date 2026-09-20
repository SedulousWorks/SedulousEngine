using Sedulous.Core.Serialization;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// The bidirectional field walk of one dock node; children recurse via presence flags.
static class DockLayoutNodeSerialization
{
	public static void SerializeLayoutNode(ISerializer ar, DockLayoutNode node)
	{
		ar.BeginObject();
		ar.Key("type");
		SerializeEnum(ar, ref node.Type);
		ar.Key("direction");
		SerializeEnum(ar, ref node.Direction);
		ar.Key("ratio");
		Serialize(ar, ref node.SplitRatio);
		ar.Key("activeTab");
		Serialize(ar, ref node.ActiveTabIndex);
		ar.Key("panels");
		SerializeList(ar, node.PanelIds);

		var hasFirst = node.First != null;
		var hasSecond = node.Second != null;
		ar.Key("hasFirst");
		Serialize(ar, ref hasFirst);
		ar.Key("hasSecond");
		Serialize(ar, ref hasSecond);
		if (hasFirst)
		{
			if (ar.Mode == .Read)
			{
				delete node.First;
				node.First = new DockLayoutNode();
			}
			ar.Key("first");
			SerializeLayoutNode(ar, node.First);
		}
		if (hasSecond)
		{
			if (ar.Mode == .Read)
			{
				delete node.Second;
				node.Second = new DockLayoutNode();
			}
			ar.Key("second");
			SerializeLayoutNode(ar, node.Second);
		}
		ar.EndObject();
	}
}
