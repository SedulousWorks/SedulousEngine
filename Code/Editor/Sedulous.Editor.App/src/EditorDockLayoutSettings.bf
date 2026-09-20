using Sedulous.Core.Serialization;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.App;

/// The dock-tree section of the per-project editor settings: a DockLayoutNode snapshot
/// from DockManager.ExportLayout, panels matched back by PersistenceId on apply. An absent
/// root means never captured. Hand-written because the stored shape is a recursive tree.
class EditorDockLayoutSettings : ISerializable
{
	public const uint64 TypeId = 0x2D4D3B1B4A3D2B7EUL;
	public const uint32 DataVersion = 1;

	public DockLayoutNode Root = null ~ delete _;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, DataVersion);
		ar.BeginObject();
		var hasRoot = Root != null;
		ar.Key("hasRoot");
		Sedulous.Core.Serialization.Serialize(ar, ref hasRoot);
		if (hasRoot)
		{
			if (ar.Mode == .Read)
			{
				delete Root;
				Root = new DockLayoutNode();
			}
			ar.Key("root");
			DockLayoutNodeSerialization.SerializeLayoutNode(ar, Root);
		}
		ar.EndObject();
		EndVersionedPayload(ar);
	}
}
