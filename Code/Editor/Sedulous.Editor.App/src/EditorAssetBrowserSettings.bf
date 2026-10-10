using Sedulous.Core.Serialization;

namespace Sedulous.Editor.App;

/// The asset browser's view mode, persisted so a project reopens in the last-used view.
/// Per-project beside the other editor-state sections: a view toggle is UI state, not a
/// project setting.
[Serializable(1)]
class EditorAssetBrowserSettings
{
	/// False is list, true is grid.
	public bool GridMode = false;
	/// The asset picker dialog's own list or grid choice, apart from the browser's: a picker
	/// is often a narrower choice (one asset type), where tiles of thumbnails read differently.
	[Appended]
	public bool PickerGridMode = false;
}
