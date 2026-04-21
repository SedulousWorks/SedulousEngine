namespace Sedulous.Editor.Core;

using System;
using System.IO;
using System.Collections;

/// User-local list of recently opened project directories.
/// Stored outside project directories (in user's app data or cache).
class RecentProjects
{
	private List<String> mPaths = new .() ~ DeleteContainerAndItems!(_);
	private String mFilePath = new .() ~ delete _;
	private int32 mMaxEntries = 10;

	/// Number of recent projects.
	public int Count => mPaths.Count;

	/// Get recent project path by index (0 = most recent).
	public StringView Get(int index) => mPaths[index];

	/// All recent paths (most recent first).
	public Span<String> Paths =>
		mPaths.Count > 0 ? .(mPaths.Ptr, mPaths.Count) : .();

	/// Initialize with the path to the recent projects file.
	public void Initialize(StringView filePath)
	{
		mFilePath.Set(filePath);
		Load();
	}

	/// Add a project path (moves to front if already present).
	public void Add(StringView path)
	{
		// Remove if already present.
		for (int i = mPaths.Count - 1; i >= 0; i--)
		{
			if (StringView(mPaths[i]) == path)
			{
				delete mPaths[i];
				mPaths.RemoveAt(i);
			}
		}

		// Insert at front.
		mPaths.Insert(0, new String(path));

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
		if (mFilePath.Length == 0) return;

		let content = scope String();
		if (File.ReadAllText(mFilePath, content) case .Err)
			return;

		for (let line in content.Split('\n'))
		{
			let trimmed = scope String(line);
			trimmed.Trim();
			if (trimmed.Length > 0)
				mPaths.Add(new String(trimmed));
		}
	}

	private void Save()
	{
		if (mFilePath.Length == 0) return;

		// Ensure parent directory exists.
		let dir = scope String();
		Path.GetDirectoryPath(mFilePath, dir);
		if (dir.Length > 0)
			Directory.CreateDirectory(dir);

		let content = scope String();
		for (let path in mPaths)
			content.AppendF("{}\n", path);

		File.WriteAllText(mFilePath, content);
	}
}
