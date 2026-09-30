using System;
using Sedulous.Content;

namespace Sedulous.Pipeline.Core;

/// One way to make a new source asset from nothing (File > New in the editor, asset_create
/// over MCP): a fresh instance of `TypeName`, seeded with its defaults, under the context's
/// group. A creator does the writing and nothing else; what follows a creation (setting the
/// default scene, cooking, opening a page) is the host's.
class AssetCreator
{
	public typealias Create = delegate Instance(AssetCreationContext context);

	public String Label = new .() ~ delete _;
	/// Creators sharing a category land in a submenu of that name ("Primitives"); empty is
	/// a top level item.
	public String Category = new .() ~ delete _;
	/// The created asset's type, full name: how a tool asks for "an input map" and how a host
	/// knows whether a builder cooks it.
	public String TypeName = new .() ~ delete _;
	/// Only a document-like creation, a scene, becomes the project's default scene when none
	/// is set; the host applies it.
	public bool SetsDefaultScene = false;
	/// Where a creation lands when no group was picked: this folder under the root, made when
	/// missing ("Materials"); empty is the root. Data rather than a choice inside Run, so a
	/// tool knows the group before creating (asset_create refuses a taken name there).
	public String DefaultGroup = new .() ~ delete _;
	/// Answers the new instance, borrowed from its group; null on a failure (no root, a write
	/// refused). OWNED.
	public Create Run ~ delete _;

	/// `run` is CONSUMED.
	public this(StringView label, StringView category, Type type, Create run, bool setsDefaultScene = false)
	{
		Label.Set(label);
		Category.Set(category);
		type.GetFullName(TypeName);
		Run = run;
		SetsDefaultScene = setsDefaultScene;
	}

	/// Sets DefaultGroup, for a registration's one-liner: `new AssetCreator(...).Under("Materials")`.
	public AssetCreator Under(StringView group)
	{
		DefaultGroup.Set(group);
		return this;
	}

	/// Runs the creator with its default group in the context: what every host calls.
	public Instance Create(Group picked, Group root, StringView sourcesRoot, StringView name = default) =>
		Run(.(picked, root, sourcesRoot, name, DefaultGroup));

	/// The group a creation lands in, WITHOUT making it: the picked group, else the default
	/// group if it exists, else the root; null when the default group does not exist yet
	/// (nothing in it can clash).
	public Group TargetFor(Group picked, Group root)
	{
		if (picked != null)
			return picked;
		if (DefaultGroup.IsEmpty)
			return root;
		return (root != null) ? root.GetGroup(DefaultGroup) : null;
	}

	/// A uniquely named instance of `type` in `group`, holding `asset` as written: the shape
	/// most creators are.
	public static Instance CreateWritten(Group group, StringView baseName, Type type, Sedulous.Core.Serialization.ISerializable asset)
	{
		if (group == null)
			return null;
		let instance = group.CreateInstance(group.UniqueInstanceName(baseName, .. scope .()), type.GetFullName(.. scope .()));
		if (instance == null)
			return null;
		if (instance.WriteObject(asset) case .Err)
			return null;
		return instance;
	}
}
