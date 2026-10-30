using System;
using Sedulous.Content;

namespace Sedulous.Editor.App;

// The group picker (Raptor's editor-gui spec, 5.2, layer 5): the picker over the project's groups,
// where an import or a new asset goes. The groups are a tree: each a row by its name, indented under
// what holds it, in the tree's order (a group, then what is under it, by name), the top one
// "Content"; the current group is checked and lit, and the search finds a group by its name,
// keeping the groups above it so two of one name read apart. Its key is the group's place:
// "Content", or "Content/" and its path.

/// The group picker's request, and the group a key names: Picker opens it.
static class GroupPicker
{
	/// The top group's name and key: it has no name of its own.
	public const String cTop = AssetsView.cTopGroup;

	/// The picker's request over `sources`' groups, `current` checked (null: none). The caller's
	/// (Picker.Open takes it).
	public static PickerRequest Request(ContentDatabase sources, Group current)
	{
		let request = new PickerRequest();
		request.Placeholder.Set("Search groups");
		request.Tree = true;
		if (current != null)
			KeyOf(current, request.Current);
		if (let top = sources.RootGroup)
			Collect(top, 0, request);
		return request;
	}

	/// A group's key, where it is from the top, appended to `outKey`.
	public static void KeyOf(Group group, String outKey)
	{
		outKey.Append(cTop);
		if (group.Parent == null)
			return;
		outKey.Append('/');
		outKey.Append(group.GetPath(.. scope .()));
	}

	/// How a group is named to the user, "Content" or its path, appended to `outName`.
	public static void ShownName(Group group, String outName)
	{
		if (group.Parent == null)
			outName.Append(cTop);
		else
			outName.Append(group.GetPath(.. scope .()));
	}

	/// The group `key` names in `sources`; null when there is none.
	public static Group Find(ContentDatabase sources, StringView key)
	{
		var group = sources.RootGroup;
		if ((group == null) || !key.StartsWith(cTop))
			return null;
		int at = cTop.Length;
		while ((group != null) && (at < key.Length))
		{
			if (key[at] != '/')
				return null; // "Contents": another word, not the top
			var end = at + 1;
			while ((end < key.Length) && (key[end] != '/'))
				end++;
			group = group.GetGroup(StringView(key, at + 1, end - at - 1));
			at = end;
		}
		return group;
	}

	/// `group`'s row, then its groups' (kept in name order by the database), depth first.
	private static void Collect(Group group, uint32 depth, PickerRequest request)
	{
		let key = KeyOf(group, .. scope .());
		let item = request.Add(key, (group.Parent == null) ? (StringView)cTop : group.Name);
		item.Glyph.Set("Editor/Icons/folder.svg");
		item.Depth = depth;
		for (let child in group.Groups)
			Collect(child, depth + 1, request);
	}
}
