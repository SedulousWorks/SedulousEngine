using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Projects;

/// One known project. Path is the project DIRECTORY as the user opened it, the identity
/// key, compared verbatim; the name and engine version are the last seen manifest snapshot.
/// When it was last opened and its pin came later, so an older store reads them as their
/// defaults.
[Serializable(1)]
class RecentProjectEntry
{
	public String Path = new .() ~ delete _;
	public String Name = new .() ~ delete _;
	public String EngineVersion = new .() ~ delete _;
	/// Unix seconds; 0 for an entry from before the editor kept it.
	[Appended]
	public int64 LastOpened = 0;
	/// Pinned: listed before the rest, whatever the order.
	[Appended]
	public bool Favourite = false;

	public void CopyFrom(RecentProjectEntry other)
	{
		Path.Set(other.Path);
		Name.Set(other.Name);
		EngineVersion.Set(other.EngineVersion);
		LastOpened = other.LastOpened;
		Favourite = other.Favourite;
	}
}
