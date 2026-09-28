using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The per user project registry, a section of the user level settings store, deliberately
/// OUTSIDE any engine install or project directory: every editor version on the machine
/// lists the same projects, and a launcher can read the same file. Ordering IS recency,
/// most recent first; no timestamps to go stale.
[Serializable(1)]
class RecentProjectsSettings
{
	public const int cMaxEntries = 20;

	public List<RecentProjectEntry> Entries = new .() ~ DeleteContainerAndItems!(_);

	public RecentProjectEntry Find(StringView path)
	{
		for (let entry in Entries)
			if (entry.Path == path)
				return entry;
		return null;
	}
}
