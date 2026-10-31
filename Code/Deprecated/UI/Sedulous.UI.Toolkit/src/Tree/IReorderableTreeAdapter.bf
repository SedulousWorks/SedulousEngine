using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A tree adapter that also allows dragging rows about.
///
/// The two operations are DIFFERENT questions. Moving puts a row at a boundary BETWEEN rows,
/// which reorders siblings; dropping INTO puts it inside another row, which reparents. An
/// adapter may allow either, both or neither, and the two have defaults so a plain reordering
/// adapter needs to say nothing about reparenting.
interface IReorderableTreeAdapter : ITreeAdapter
{
	/// Whether the row at one flat position may move to a boundary at another.
	bool CanMove(int32 fromPosition, int32 toPosition);

	void MoveItem(int32 fromPosition, int32 toPosition);

	/// Whether the row at one flat position may be dropped INSIDE the row at another.
	/// Unsupported by default, which leaves a pure reordering adapter unchanged.
	bool CanDropInto(int32 fromPosition, int32 toPosition) => false;

	void DropInto(int32 fromPosition, int32 toPosition) {}
}
