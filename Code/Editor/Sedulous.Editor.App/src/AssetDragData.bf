using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The typed drag payload for asset-browser drags: the dragged instance's Guid, its asset
/// type name (what drop targets filter on) and the display name (for reject messages and
/// drag visuals). Format "asset/instance"; recover the subtype with `as`.
class AssetDragData : DragData
{
	public const String cFormat = "asset/instance";

	public Guid Id;
	public String AssetTypeName = new .() ~ delete _;
	public String DisplayName = new .() ~ delete _;

	public this(Guid id, StringView assetTypeName, StringView displayName) : base(cFormat)
	{
		Id = id;
		AssetTypeName.Set(assetTypeName);
		DisplayName.Set(displayName);
	}
}
