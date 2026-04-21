namespace Sedulous.Editor.Core;

using System;
using System.Collections;

/// Global asset browser selection. Independent from per-scene entity selection.
class AssetSelection
{
	private List<String> mSelectedPaths = new .() ~ DeleteContainerAndItems!(_);
	public Event<delegate void(AssetSelection)> OnSelectionChanged ~ _.Dispose();

	public Span<String> SelectedPaths =>
		mSelectedPaths.Count > 0 ? .(mSelectedPaths.Ptr, mSelectedPaths.Count) : .();

	public StringView PrimarySelection =>
		mSelectedPaths.Count > 0 ? mSelectedPaths[0] : "";

	public void SelectAsset(StringView path)
	{
		ClearInternal();
		mSelectedPaths.Add(new String(path));
		OnSelectionChanged(this);
	}

	public void SelectAssets(Span<StringView> paths)
	{
		ClearInternal();
		for (let path in paths)
			mSelectedPaths.Add(new String(path));
		OnSelectionChanged(this);
	}

	public void Clear()
	{
		ClearInternal();
		OnSelectionChanged(this);
	}

	private void ClearInternal()
	{
		for (let path in mSelectedPaths)
			delete path;
		mSelectedPaths.Clear();
	}
}
