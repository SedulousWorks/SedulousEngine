using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// The asset picker (Raptor's editor-gui spec, 5.2, layer 5): the picker over the project's assets
// of the types a reference takes (none named, or AssetPickerSlot.cAnyAsset among them: any), each
// under its group ("Content" for the top) in the groups' name order, its type beside its name, its
// type's glyph, and the favourites starred (the picker lists them first). Its key is the asset's
// guid as text; None clears the reference. With none of those types it says so, naming them.

/// The asset picker's request: Picker opens it.
static class AssetPicker
{
	/// The section the top group's assets are under: the top group has no name of its own.
	public const String cTopGroup = "Content";

	/// The picker's request over `sources`' assets of `types` (asset type names, full or short:
	/// AssetTypeNames.Matches), those in `favourites` starred, `current` checked (nil: none). A
	/// glyph is `icons`' for the Beef type `registry` resolves the asset's type name to (an
	/// instance names its type in full). The caller's (Picker.Open takes it).
	public static PickerRequest Request(ContentDatabase sources, EditorIcons icons, EditorPageRegistry registry,
		Span<Guid> favourites, Span<String> types, Guid current)
	{
		let request = new PickerRequest();
		request.Placeholder.Set("Search assets");
		request.AllowNone = true;
		if (!current.IsNil)
			KeyOf(current, request.Current);
		if (let top = sources.RootGroup)
			Collect(top, icons, registry, favourites, types, request);
		if (TakesAny(types))
		{
			request.EmptyTitle.Set("No assets yet");
		}
		else
		{
			request.EmptyTitle.Append("No ");
			for (int i < types.Length)
			{
				if (i > 0)
					request.EmptyTitle.Append(" or ");
				request.EmptyTitle.Append(types[i]);
			}
			request.EmptyTitle.Append(" yet");
		}
		request.EmptyText.Set("Import or create one in the Assets panel.");
		return request;
	}

	/// What a pick answers for an asset: its guid as text, appended to `outKey`.
	public static void KeyOf(Guid id, String outKey)
	{
		id.ToString(outKey);
	}

	/// Whether a picker over `types` lists an asset of type `typeName` (full or short).
	public static bool Takes(StringView typeName, Span<String> types) =>
		TakesAny(types) || AssetPickerSlot.Accepts(types, typeName);

	/// None named, or the wildcard among them.
	private static bool TakesAny(Span<String> types)
	{
		for (let type in types)
		{
			if (type == AssetPickerSlot.cAnyAsset)
				return true;
		}
		return types.IsEmpty;
	}

	/// `group`'s assets, then its groups' (kept in name order by the database), depth first.
	private static void Collect(Group group, EditorIcons icons, EditorPageRegistry registry, Span<Guid> favourites,
		Span<String> types, PickerRequest request)
	{
		let section = scope String();
		if (group.Parent == null)
			section.Set(cTopGroup);
		else
			group.GetPath(section);
		let key = scope String();
		for (let instance in group.Instances)
		{
			if (!Takes(instance.TypeName, types))
				continue;
			key.Clear();
			KeyOf(instance.Id, key);
			// The short name, as the slot's and the builders' type names read.
			let item = request.Add(key, instance.Name, section, AssetTypeNames.Short(instance.TypeName));
			for (let favourite in favourites)
				item.Favourite = item.Favourite || (favourite == instance.Id);
			if (let type = registry.ResolveType(instance.TypeName))
			{
				let icon = icons.For(type, "Asset");
				item.Glyph.Set(icon.Source);
				item.GlyphClass.Set(icon.Class);
			}
		}
		for (let child in group.Groups)
			Collect(child, icons, registry, favourites, types, request);
	}
}
