namespace Sedulous.Editor.App;

using Sedulous.UI;
using Sedulous.Engine.Core;

/// Drag payload for hierarchy entity reorder/reparent.
class HierarchyDragData : DragData
{
	public EntityHandle Entity;
	public int32 NodeId;

	public this(EntityHandle entity, int32 nodeId) : base("hierarchy/entity")
	{
		Entity = entity;
		NodeId = nodeId;
	}
}
