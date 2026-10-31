namespace Sedulous.UI;

/// Implemented by a view that accepts drops.
///
/// Found by walking the parent chain of the hit view, so a child that does not itself accept
/// drops still lets its container do so.
interface IDropTarget
{
	/// Whether this target accepts the payload at this position, asked EVERY frame the drag
	/// is over it: what a target will accept can depend on where the pointer is.
	DragDropEffects CanAcceptDrop(DragData data, float localX, float localY);

	void OnDragEnter(DragData data, float localX, float localY);
	void OnDragOver(DragData data, float localX, float localY);
	void OnDragLeave(DragData data);

	/// Answers the effect actually performed, which need not be the one offered.
	DragDropEffects OnDrop(DragData data, float localX, float localY);
}
