using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Shaders;

/// The DEVELOPMENT source provider: built in shaders as real files under a shader root.
///
/// The naming convention is the whole interface: the shader NAME is the file stem and the
/// stage is the double extension, so `tonemap.ps.hlsl` serves the fragment stage of
/// "tonemap". Shared code lives in `.hlsli` beside them, and the root doubles as the DXC
/// include path.
///
/// The manifest is scanned EAGERLY, because built ins have to be enumerable for tooling,
/// but the sources themselves are read lazily.
class FileShaderSourceProvider : IShaderSourceProvider
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

	private String mRoot = new String() ~ delete _;
	private NativeFileSystem mMount = null ~ delete _;
	/// Owned by the mount.
	private IChangeSource mChanges = null;
	private List<Entry> mEntries = new List<Entry>() ~ DeleteContainerAndItems!(_);
	private uint32 mCallsSinceSweep = 0;

	public StringView RootDirectory => mRoot;
	public int ShaderFileCount => mEntries.Count;

	/// Mounts the root and scans the manifest.
	///
	/// An error when the root does not exist, which a caller falls back from loudly rather
	/// than silently serving nothing.
	public Result<void> Initialize(StringView rootDirectory)
	{
		if (!DirectoryExists(rootDirectory))
			return .Err;

		mRoot.Set(rootDirectory);
		mMount = new NativeFileSystem(rootDirectory);

		let entries = scope List<DirEntry>();
		defer
		{
			for (var entry in ref entries)
				entry.Dispose();
		}
		if (mMount.Enumerate("", entries) case .Err)
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
			mapped.FileName.Set(entry.Name);
			mEntries.Add(mapped);
		}

		mChanges = mMount.ChangeSource;
		// The WHOLE mount, recursively, so an .hlsli edit is seen too.
		mChanges.Track("");
		return .Ok;
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
