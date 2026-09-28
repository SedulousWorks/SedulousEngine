using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.VFS;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.Core;

/// The headless core of the project manager over the RecentProjects section: touch, remove,
/// the manifest probe, the engine version relation, and the manifest backup the upgrade
/// prompt offers.
static class ProjectRegistry
{
	/// Records `path` as the most recently opened project, inserting or moving to the front
	/// with a fresh display snapshot, capped at cMaxEntries. Marks the section changed; the
	/// caller persists the store.
	public static void TouchRecentProject(Settings store, StringView path, StringView name, StringView engineVersion)
	{
		let registry = store.Section<RecentProjectsSettings>();
		for (int i < registry.Entries.Count)
		{
			if (registry.Entries[i].Path == path)
			{
				delete registry.Entries[i];
				registry.Entries.RemoveAt(i);
				break;
			}
		}
		let entry = new RecentProjectEntry();
		entry.Path.Set(path);
		entry.Name.Set(name);
		entry.EngineVersion.Set(engineVersion);
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
