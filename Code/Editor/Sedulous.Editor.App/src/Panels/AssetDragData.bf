namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;

/// Drag data for asset browser items. Carries the file path, extension,
/// and optional GUID for the dragged asset.
class AssetDragData : DragData
{
	/// Absolute filesystem path to the asset.
	public String AbsolutePath = new .() ~ delete _;

	/// URI path (scheme://locator) for resource loading.
	public String UriPath = new .() ~ delete _;

	/// File extension (e.g. ".prefab", ".mesh").
	public String Extension = new .() ~ delete _;

	/// Resource GUID if registered in the project index.
	public Guid ResourceId;

	public this(StringView absolutePath, StringView uriPath, StringView @extension, Guid resourceId)
		: base("asset/file")
	{
		AbsolutePath.Set(absolutePath);
		UriPath.Set(uriPath);
		Extension.Set(@extension);
		ResourceId = resourceId;
	}
}
