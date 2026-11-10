using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Projects;

/// The per user project registry, a section of the user level settings store, deliberately
/// OUTSIDE any engine install or project directory: every editor version on the machine
/// lists the same projects, and a launcher can read the same file. Ordering IS recency,
/// most recent first; each entry also keeps when it was last opened (Unix seconds, which the
/// manager shows as "2 hours ago") and whether the user pinned it.
[Serializable(1)]
class RecentProjectsSettings
{
	public const int cMaxEntries = 20;

	public List<RecentProjectEntry> Entries = new .() ~ DeleteContainerAndItems!(_);
	/// The launcher shows the projects as a grid of their pictures, else as a list.
	[Appended]
	public bool GridView = false;
	/// The list's order: by name, else by when each was last opened.
	[Appended]
	public bool SortByName = false;
	/// The folder the last project was made or downloaded in, where the next one starts.
	[Appended]
	public String LastLocation = new .() ~ delete _;

	/// Becomes a copy of `other`: its entries (copied) and its layout.
	public void CopyFrom(RecentProjectsSettings other)
	{
		if (other === this)
			return;
		ClearAndDeleteItems!(Entries);
		for (let entry in other.Entries)
		{
			let copy = new RecentProjectEntry();
			copy.CopyFrom(entry);
			Entries.Add(copy);
		}
		GridView = other.GridView;
		SortByName = other.SortByName;
		LastLocation.Set(other.LastLocation);
	}

	public RecentProjectEntry Find(StringView path)
	{
		for (let entry in Entries)
			if (entry.Path == path)
				return entry;
		return null;
	}
}
