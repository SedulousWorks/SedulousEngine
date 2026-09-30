using System;
using Sedulous.Content;

namespace Sedulous.Pipeline.Core;

/// Where a creator makes its asset: the group the user picked, if any, the source database's
/// root, and the project's sources folder, where a file-backed asset writes its starter file.
/// No editor: a headless host creates through the same creators.
struct AssetCreationContext
{
	/// The group the creation was asked for; null leaves the choice to the creator, which
	/// uses its default group under the root.
	public Group Picked;
	public Group Root;
	/// Absolute; empty when the host has no sources folder, which a file-backed creator
	/// refuses.
	public StringView SourcesRoot;
	/// The name asked for; empty lets the creator use its own ("Material", "InputMap"). A
	/// creator makes it unique in the group, so the caller that wants it EXACT (asset_create)
	/// refuses a taken name first.
	public StringView Name;
	/// The creator's folder under the root when nothing was picked (AssetCreator.DefaultGroup);
	/// empty is the root itself.
	public StringView DefaultGroup;

	public this(Group picked, Group root, StringView sourcesRoot, StringView name = default, StringView defaultGroup = default)
	{
		Picked = picked;
		Root = root;
		SourcesRoot = sourcesRoot;
		Name = name;
		DefaultGroup = defaultGroup;
	}

	/// The name asked for, else the creator's `fallback`.
	public StringView NameOr(StringView fallback) => Name.IsEmpty ? fallback : Name;

	/// The picked group, else the default group under the root (made when missing), else the
	/// root.
	public Group Target => DefaultGroup.IsEmpty ? ((Picked != null) ? Picked : Root) : TargetOr(DefaultGroup);

	/// The picked group, else `name` under the root, made when missing: a material lands in
	/// Materials/ unless the user chose where.
	public Group TargetOr(StringView name)
	{
		if (Picked != null)
			return Picked;
		if (Root == null)
			return null;
		var group = Root.GetGroup(name);
		if (group == null)
			group = Root.CreateGroup(name);
		return group;
	}
}
