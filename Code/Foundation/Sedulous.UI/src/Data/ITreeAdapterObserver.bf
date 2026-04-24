namespace Sedulous.UI;

/// Observer for tree adapter data changes. FlattenedTreeAdapter implements this.
public interface ITreeAdapterObserver
{
	/// Entire tree data changed - rebuild everything.
	void OnTreeDataChanged();
}
