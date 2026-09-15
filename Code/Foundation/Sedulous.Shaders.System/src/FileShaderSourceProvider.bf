using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Shaders;

/// The DEVELOPMENT source provider: built in shaders as files in a FOLDER OF A MOUNT.
///
/// The naming convention is the whole interface: the shader NAME is the file stem and the
/// stage is the double extension, so `tonemap.ps.hlsl` serves the fragment stage of
/// "tonemap". Shared code lives in `.hlsli` beside them.
///
/// It doubles as the compiler's include resolver, so an `#include` is read back through the
/// same mount rather than off the native filesystem. That is what lets a pak backed mount
/// serve a corpus a directory would otherwise have to.
///
/// The manifest is scanned EAGERLY, because built ins have to be enumerable for tooling,
/// but the sources themselves are read lazily.
class FileShaderSourceProvider : IShaderSourceProvider, IShaderIncludeResolver
{
	/// PollChanges is called once per frame and the sweep is proportional to the file count,
	/// so only every Nth call actually sweeps. About a second at sixty frames per second:
	/// this is hot reload, not a race.
	public const uint32 PollEveryNCalls = 60;

	private class Entry
	{
		/// The shader name, which is the file stem.
		public String Name = new String() ~ delete _;
		public ShaderStage Stage;
		/// Mount relative, such as "tonemap.ps.hlsl".
		public String FileName = new String() ~ delete _;
	}

	/// Mount relative, and "" means the mount root.
	private String mFolder = new String() ~ delete _;
	/// BORROWED: the application owns the data mount and outlives this.
	private IFileSystem mMount = null;
	/// Owned by the mount.
	private IChangeSource mChanges = null;
	private List<Entry> mEntries = new List<Entry>() ~ DeleteContainerAndItems!(_);
	private uint32 mCallsSinceSweep = 0;

	/// The folder the manifest was scanned from, mount relative.
	public StringView Folder => mFolder;
	public int ShaderFileCount => mEntries.Count;
	/// Whether the mount can report changes, which is what makes hot reload live. A native
	/// mount can; a pak cannot.
	public bool SupportsReload => mChanges != null;

	/// Scans a folder of a mount for the manifest.
	///
	/// An error when the mount cannot enumerate or the folder is not there, which a caller
	/// falls back from loudly rather than silently serving nothing.
	public Result<void> Initialize(IFileSystem fileSystem, StringView folder)
	{
		mMount = fileSystem;
		mFolder.Set(folder);
		mEntries.Clear();
		mChanges = null;

		let enumerable = fileSystem as IEnumerableFileSystem;
		if (enumerable == null)
			return .Err;
		if (!folder.IsEmpty && !fileSystem.Exists(folder))
			return .Err;

		let entries = scope List<DirEntry>();
		defer
		{
			for (var entry in ref entries)
				entry.Dispose();
		}
		if (enumerable.Enumerate(folder, entries) case .Err)
			return .Err;

		for (let entry in entries)
		{
			// A flat root: subdirectories are not searched, matching the cook.
			if (entry.IsDirectory)
				continue;

			ShaderStage stage = .Vertex;
			let stem = scope String();
			if (!ShaderPackCooker.ParseStageFile(entry.Name, ref stage, stem))
				continue; // an .hlsli, or an unrelated file

			let mapped = new Entry();
			mapped.Name.Set(stem);
			mapped.Stage = stage;
			Locate(entry.Name, mapped.FileName);
			mEntries.Add(mapped);
		}

		// Hot reload only where the mount can watch.
		if (let watchable = fileSystem as IWatchableFileSystem)
		{
			mChanges = watchable.ChangeSource;
			// The WHOLE folder, recursively, so an .hlsli edit is seen too.
			mChanges.Track(folder);
		}
		return .Ok;
	}

	/// A folder relative name as a mount relative path.
	private void Locate(StringView name, String outPath)
	{
		if (mFolder.IsEmpty)
			outPath.Set(name);
		else
			PathJoin(mFolder, name, outPath);
	}

	/// The preprocessor asks with the path as WRITTEN, relative to the including file: a first
	/// level include arrives bare and is looked up in the folder, and a nested one already
	/// carries the folder prefix. Both are tried, folder first.
	public bool LoadInclude(StringView path, String outSource)
	{
		if ((mMount == null) || path.IsEmpty)
			return false;

		let inFolder = Locate(path, .. scope String());
		if (mMount.Exists(inFolder) && ReadWholeFile(inFolder, outSource))
			return true;

		return (inFolder != path) && mMount.Exists(path) && ReadWholeFile(path, outSource);
	}

	public bool FetchSource(StringView name, ShaderStage stage, String outSource)
	{
		for (let entry in mEntries)
		{
			if ((entry.Stage == stage) && (entry.Name == name))
				return ReadWholeFile(entry.FileName, outSource);
		}
		return false;
	}

	public void CollectShaderNames(List<String> outNames)
	{
		for (let entry in mEntries)
			AppendUnique(outNames, entry.Name);
	}

	public bool PollChanges(List<String> outChangedNames)
	{
		if (mChanges == null)
			return false;
		if (!ThrottleElapsed())
			return false;

		let changedFiles = scope List<String>();
		defer { ClearAndDeleteItems!(changedFiles); }
		if (!mChanges.Poll(changedFiles))
			return false;

		var any = false;
		for (let file in changedFiles)
		{
			if (file.EndsWith(".hlsli"))
			{
				// Which shaders include it is unknown, so EVERYTHING this provider serves
				// reloads. A full recompile is the correct answer in development, and the
				// alternative is tracking an include graph to save a second.
				for (let entry in mEntries)
				{
					any = true;
					AppendUnique(outChangedNames, entry.Name);
				}
				continue;
			}

			for (let entry in mEntries)
			{
				if (entry.FileName == file)
				{
					any = true;
					AppendUnique(outChangedNames, entry.Name);
					break;
				}
			}
		}
		return any;
	}

	private static void AppendUnique(List<String> outNames, StringView name)
	{
		for (let existing in outNames)
		{
			if (existing == name)
				return;
		}
		outNames.Add(new String(name));
	}

	private bool ReadWholeFile(StringView fileName, String outSource)
	{
		// CLEARED first: LoadInclude tries two candidates, and a partial read from the first
		// would otherwise be prefixed onto the second.
		outSource.Clear();

		let stream = mMount.Open(fileName, .Read);
		if (stream == null)
			return false;
		defer delete stream;

		let size = stream.Size();
		if (size < 0)
			return false;
		if (size == 0)
			return true;

		let bytes = scope uint8[(int)size];
		if (stream.Read(bytes) != (int)size)
			return false;
		outSource.Append(StringView((char8*)bytes.Ptr, (int)size));
		return true;
	}

	private bool ThrottleElapsed()
	{
		mCallsSinceSweep++;
		if (mCallsSinceSweep < PollEveryNCalls)
			return false;
		mCallsSinceSweep = 0;
		return true;
	}
}
