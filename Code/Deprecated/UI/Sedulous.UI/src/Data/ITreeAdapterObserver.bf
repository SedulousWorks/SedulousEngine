namespace Sedulous.UI;

/// Told when a tree's data changed. FlattenedTreeAdapter implements this to rebuild its flat
/// view of the tree.
interface ITreeAdapterObserver
{
	void OnTreeDataChanged();
}
