using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The browser's group tree: the shared group table with renamable name-label rows, the root
/// shown as "Content" and not renamable.
class AssetGroupTreeAdapter : GroupTreeAdapter
{
	private AssetsView mOwner;

	public this(AssetsView owner) { mOwner = owner; }

	public override View CreateView(int32 viewType)
	{
		let row = new AssetNameLabel();
		row.FontSize.Value = 13.0f;
		row.Configure(new (label, newName) => { mOwner.ApplyRename(label, newName); });
		return row;
	}

	public override void BindView(View view, int32 nodeId, int32 depth, bool isExpanded)
	{
		let group = GroupAt(nodeId);
		let row = view as AssetNameLabel;
		if ((group == null) || (row == null))
			return;
		let isRoot = group.Parent == null;
		row.BindTarget(.Empty, group);
		row.SetText(isRoot ? "Content" : group.Name);
		row.SlowClickToEdit.Value = !isRoot;
		row.TextOffsetX.Value = (float)(depth + 1) * 18.0f;
	}
}
