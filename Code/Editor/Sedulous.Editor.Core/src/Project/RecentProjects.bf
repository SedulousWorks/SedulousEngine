namespace Sedulous.Editor.Core;

using System;
using System.IO;
using System.Collections;
using Sedulous.Serialization;

/// User-local list of recently opened project directories.
/// Stored outside project directories (in user's app data or cache).
/// Uses OpenDDL serialization for consistency with project files.
class RecentProjects
{
	private List<String> mPaths = new .() ~ DeleteContainerAndItems!(_);
	private String mFilePath = new .() ~ delete _;
	private ISerializerProvider mSerializerProvider;
	private int32 mMaxEntries = 10;

	/// Number of recent projects.
	public int Count => mPaths.Count;

	/// Get recent project path by index (0 = most recent).
	public StringView Get(int index) => mPaths[index];

	/// All recent paths (most recent first).
	public Span<String> Paths =>
		mPaths.Count > 0 ? .(mPaths.Ptr, mPaths.Count) : .();

	/// Initialize with the path to the recent projects file and serializer provider.
	public void Initialize(StringView filePath, ISerializerProvider provider)
	{
		mFilePath.Set(filePath);
		mSerializerProvider = provider;
		Load();
	}

	/// Add a project path (moves to front if already present).
	public void Add(StringView path)
	{
		// Copy first - path may be a StringView into an entry we're about to delete.
		let pathCopy = scope String(path);

		// Remove if already present.
		for (int i = mPaths.Count - 1; i >= 0; i--)
		{
			if (StringView(mPaths[i]) == pathCopy)
			{
				delete mPaths[i];
				mPaths.RemoveAt(i);
			}
		}

		// Insert at front.
		mPaths.Insert(0, new String(pathCopy));

		// Trim oldest.
		while (mPaths.Count > mMaxEntries)
		{
			delete mPaths.Back;
			mPaths.PopBack();
		}

		Save();
	}

	/// Remove a project path.
	public void Remove(StringView path)
	{
		for (int i = mPaths.Count - 1; i >= 0; i--)
		{
			if (StringView(mPaths[i]) == path)
			{
				delete mPaths[i];
				mPaths.RemoveAt(i);
			}
		}
		Save();
	}

	private void Load()
	{
		if (mFilePath.Length == 0 || mSerializerProvider == null) return;

		let content = scope String();
		if (File.ReadAllText(mFilePath, content) case .Err)
			return;

		let reader = mSerializerProvider.CreateReader(content);
		if (reader == null)
			return;
		defer delete reader;

		var count = (int32)0;
		reader.BeginArray("Projects", ref count);
		for (int32 i = 0; i < count; i++)
		{
			reader.BeginObject("");
			let path = new String();
			reader.String("path", path);
			mPaths.Add(path);
			reader.EndObject();
		}
		reader.EndArray();
	}

	private void Save()
	{
		if (mFilePath.Length == 0 || mSerializerProvider == null) return;

		// Ensure parent directory exists.
		let dir = scope String();
		Path.GetDirectoryPath(mFilePath, dir);
		if (dir.Length > 0)
			Directory.CreateDirectory(dir);

		let writer = mSerializerProvider.CreateWriter();
		if (writer == null) return;
		defer delete writer;

		var count = (int32)mPaths.Count;
		writer.BeginArray("Projects", ref count);
		for (let path in mPaths)
		{
			writer.BeginObject("");
			writer.String("path", path);
			writer.EndObject();
		}
		writer.EndArray();

		let output = scope String();
		mSerializerProvider.GetOutput(writer, output);
		File.WriteAllText(mFilePath, output);
	}
}
