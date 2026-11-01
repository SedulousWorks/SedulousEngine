using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Project;

/// The headless core of the project manager over the RecentProjects section: touch, remove,
/// the manifest probe, the engine version relation, and the manifest backup the upgrade
/// prompt offers.
static class ProjectRegistry
{
	private static StringView[12] cMonths = .("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

	/// Records `path` as the most recently opened project, opened now by the wall clock.
	public static void TouchRecentProject(Settings store, StringView path, StringView name, StringView engineVersion)
		=> TouchRecentProject(store, path, name, engineVersion, GetUnixTime());

	/// Records `path` as the most recently opened project, opened at `openedAt` (Unix seconds),
	/// inserting or moving to the front with its pin kept and a fresh display snapshot, capped at
	/// cMaxEntries. Marks the section changed; the caller persists the store.
	public static void TouchRecentProject(Settings store, StringView path, StringView name, StringView engineVersion, int64 openedAt)
	{
		let registry = store.Section<RecentProjectsSettings>();
		bool favourite = false;
		for (int i < registry.Entries.Count)
		{
			if (registry.Entries[i].Path == path)
			{
				favourite = registry.Entries[i].Favourite;
				delete registry.Entries[i];
				registry.Entries.RemoveAt(i);
				break;
			}
		}
		let entry = new RecentProjectEntry();
		entry.Path.Set(path);
		entry.Name.Set(name);
		entry.EngineVersion.Set(engineVersion);
		entry.LastOpened = openedAt;
		entry.Favourite = favourite;
		registry.Entries.Insert(0, entry);
		while (registry.Entries.Count > RecentProjectsSettings.cMaxEntries)
			delete registry.Entries.PopBack();
		store.MarkChanged<RecentProjectsSettings>();
	}

	/// Removes `path`, a dead or unwanted row. True when removed.
	public static bool RemoveRecentProject(Settings store, StringView path)
	{
		let registry = store.Section<RecentProjectsSettings>();
		for (int i < registry.Entries.Count)
		{
			if (registry.Entries[i].Path == path)
			{
				delete registry.Entries[i];
				registry.Entries.RemoveAt(i);
				store.MarkChanged<RecentProjectsSettings>();
				return true;
			}
		}
		return false;
	}

	/// Pins or unpins `path`; false when it is not in the list. Marks the section changed.
	public static bool SetRecentProjectFavourite(Settings store, StringView path, bool favourite)
	{
		let entry = store.Section<RecentProjectsSettings>().Find(path);
		if (entry == null)
			return false;
		entry.Favourite = favourite;
		store.MarkChanged<RecentProjectsSettings>();
		return true;
	}

	/// Points the entry at `from` at the folder the project is in now (Locate... on a missing
	/// project), keeping its place, pin and time. False when `from` is not listed, or `to` already
	/// is (that entry stays; the caller removes this one if the user wants).
	public static bool RelocateRecentProject(Settings store, StringView from, StringView to)
	{
		let registry = store.Section<RecentProjectsSettings>();
		if (registry.Find(to) != null)
			return false;
		let entry = registry.Find(from);
		if (entry == null)
			return false;
		entry.Path.Set(to);
		store.MarkChanged<RecentProjectsSettings>();
		return true;
	}

	/// The entries the manager lists, in its order, into `outEntries` (BORROWED from `registry`,
	/// valid until it changes): those matching `query` (in the name or the folder, any case; empty
	/// matches all), pinned ones first, then by name or by recency (the list's own order).
	public static void ArrangeRecentProjects(RecentProjectsSettings registry, StringView query, bool byName, List<RecentProjectEntry> outEntries)
	{
		outEntries.Clear();
		for (let entry in registry.Entries)
			if (query.IsEmpty || entry.Name.Contains(query, true) || entry.Path.Contains(query, true))
				outEntries.Add(entry);
		// An insertion sort: stable, so the list's own order (recency) breaks every tie, which
		// List.Sort would not keep; the list is at most cMaxEntries long.
		for (int i = 1; i < outEntries.Count; i++)
		{
			let entry = outEntries[i];
			int at = i;
			while ((at > 0) && Before(entry, outEntries[at - 1], byName))
			{
				outEntries[at] = outEntries[at - 1];
				at--;
			}
			outEntries[at] = entry;
		}
	}

	// Pinned first, then by name when asked.
	private static bool Before(RecentProjectEntry a, RecentProjectEntry b, bool byName)
	{
		if (a.Favourite != b.Favourite)
			return a.Favourite;
		return byName && (CompareNames(a.Name, b.Name) < 0);
	}

	/// ASCII letters in any case, then the shorter first.
	private static int CompareNames(StringView a, StringView b)
	{
		for (int i = 0; (i < a.Length) && (i < b.Length); i++)
		{
			let x = a[i].ToLower;
			let y = b[i].ToLower;
			if (x != y)
				return (x < y) ? -1 : 1;
		}
		return a.Length <=> b.Length;
	}

	/// When a project was last opened, said for a person at `now`: "Just now", "5 minutes ago",
	/// "3 hours ago", "Yesterday", "4 days ago", "2 weeks ago", then the date ("19 Oct 2026").
	/// Nothing for an entry that never kept one (0). `offset` is the local time zone's
	/// (GetLocalTimeOffset), so a date is the user's own.
	public static void DescribeLastOpened(int64 openedAt, int64 now, int64 offset, String outText)
	{
		if (openedAt <= 0)
			return;
		let ago = (now > openedAt) ? (now - openedAt) : 0;
		if (ago < 60)
		{
			outText.Append("Just now");
			return;
		}
		if (ago < 3600)
		{
			Count(ago / 60, "minute", outText);
			return;
		}
		// From here by calendar days, so "Yesterday" is the day before today, not 24 hours ago.
		let days = (now + offset) / 86400 - (openedAt + offset) / 86400;
		if (days == 0)
			Count(ago / 3600, "hour", outText);
		else if (days == 1)
			outText.Append("Yesterday");
		else if (days < 14)
			Count(days, "day", outText);
		else if (days < 35)
			Count(days / 7, "week", outText);
		else
		{
			let date = CivilTimeOf(openedAt + offset);
			outText.AppendF("{} {} {}", date.Day, cMonths[date.Month - 1], date.Year);
		}
	}

	/// The exact local time `openedAt` names, for a tooltip: "31 Oct 2026, 18:42". Nothing for 0.
	public static void DescribeTime(int64 openedAt, int64 offset, String outText)
	{
		if (openedAt <= 0)
			return;
		let t = CivilTimeOf(openedAt + offset);
		outText.AppendF("{} {} {}, {}{}:{}{}", t.Day, cMonths[t.Month - 1], t.Year, (t.Hour < 10) ? "0" : "", t.Hour,
			(t.Minute < 10) ? "0" : "", t.Minute);
	}

	// "1 minute ago", "3 hours ago".
	private static void Count(int64 n, StringView unit, String outText)
	{
		outText.AppendF("{} {}{} ago", n, unit, (n == 1) ? "" : "s");
	}

	/// Reads a project's manifest WITHOUT opening the project: no databases, no scaffolding.
	/// NotFound when there is no manifest at `directory`.
	public static Result<void, ErrorCode> ProbeProject(StringView directory, ProjectSettings outSettings)
	{
		if (!DirectoryExists(directory))
			return .Err(.NotFound);
		let fs = scope NativeFileSystem(directory);
		return ProjectManifest.Load(fs, outSettings);
	}

	/// "major.minor.patch", all three numeric, against this engine's constants.
	public static EngineVersionRelation CompareProjectEngineVersion(StringView projectVersion)
	{
		if (projectVersion.IsEmpty)
			return .Unstamped;
		uint32[3] parts = .(0, 0, 0);
		int part = 0;
		bool anyDigit = false;
		for (let c in projectVersion)
		{
			if (c.IsDigit)
			{
				parts[part] = parts[part] * 10 + (uint32)(c - '0');
				anyDigit = true;
			}
			else if ((c == '.') && (part < 2) && anyDigit)
			{
				part++;
				anyDigit = false;
			}
			else
			{
				return .Unstamped;
			}
		}
		if ((part != 2) || !anyDigit)
			return .Unstamped;
		uint32[3] engine = .(EngineVersion.Major, EngineVersion.Minor, EngineVersion.Patch);
		for (int i < 3)
		{
			if (parts[i] < engine[i])
				return .ProjectOlder;
			if (parts[i] > engine[i])
				return .ProjectNewer;
		}
		return .Same;
	}

	/// Backs the manifest up before an engine upgrade rewrites it: Project.xml copied to
	/// "Project.xml.<stampedVersion>.bak" beside it, "unstamped" for a manifest predating
	/// the stamp, overwriting an older backup for the SAME version. Content assets are not
	/// copied: they migrate through their own versioned serializers, and whole tree safety
	/// is version control's job.
	public static Result<void, ErrorCode> BackupProjectManifest(StringView directory, String outBackupPath)
	{
		let probed = scope ProjectSettings();
		if (ProbeProject(directory, probed) case .Err(let error))
			return .Err(error);
		let manifest = PathJoin(directory, ProjectLayout.ManifestFile, .. scope .());
		outBackupPath.Set(manifest);
		outBackupPath.Append('.');
		outBackupPath.Append(probed.EngineVersion.IsEmpty ? "unstamped" : probed.EngineVersion);
		outBackupPath.Append(".bak");
		let bytes = scope List<uint8>();
		if (ReadFile(manifest, bytes) case .Err(let readError))
			return .Err(readError);
		return WriteFile(outBackupPath, bytes);
	}
}
