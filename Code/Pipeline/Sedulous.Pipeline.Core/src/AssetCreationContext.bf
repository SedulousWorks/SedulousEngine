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

	public this(Group picked, Group root, StringView sourcesRoot)
	{
		Picked = picked;
		Root = root;
		SourcesRoot = sourcesRoot;
	}

	/// The picked group, else the root.
	public Group Target => (Picked != null) ? Picked : Root;

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
