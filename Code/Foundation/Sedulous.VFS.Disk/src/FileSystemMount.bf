using System;
using System.IO;
using System.Collections;
using Sedulous.VFS;

namespace Sedulous.VFS.Disk;

/// A mount backed by a directory on disk. Implements every capability interface in
/// `Sedulous.VFS`: read, enumerate, watch, write.
///
/// Locators are forward-slash, mount-relative paths. The mount's `RootPath` is the
/// only path translation - everything else operates in locator space.
public class FileSystemMount : IMount, IEnumerableMount, IWatchableMount, IWritableMount
{
	private String mRootPath = new .() ~ delete _;
	private FileSystemChangeSource mChangeSource ~ delete _;

	/// The absolute filesystem path this mount is rooted at.
	public StringView RootPath => mRootPath;

	public this(StringView rootPath)
	{
		mRootPath.Set(rootPath);
		mRootPath.Replace('\\', '/');
		// Drop trailing slash so combine logic is uniform.
		while (mRootPath.Length > 0 && mRootPath[mRootPath.Length - 1] == '/')
			mRootPath.RemoveFromEnd(1);
	}

	// === IMount ===

	public bool Exists(StringView locator)
	{
		let abs = scope String();
		ResolveAbsolute(locator, abs);
		return File.Exists(abs) || Directory.Exists(abs);
	}

	public Result<Stream, MountError> Open(StringView locator)
	{
		let abs = scope String();
		ResolveAbsolute(locator, abs);

		let stream = new FileStream();
		if (stream.Open(abs, .Read, .Read) case .Err(let err))
		{
			delete stream;
			switch (err)
			{
			case .NotFound: return .Err(.NotFound);
			case .SharingViolation: return .Err(.AccessDenied);
			default: return .Err(.IOError);
			}
		}
		return .Ok(stream);
	}

	// === IEnumerableMount ===

	public void Enumerate(StringView folderLocator, List<String> outEntries)
	{
		let folderAbs = scope String();
		ResolveAbsolute(folderLocator, folderAbs);
		if (!Directory.Exists(folderAbs))
			return;

		// Files first, then directories - stable ordering aids debugging.
		for (let entry in Directory.EnumerateFiles(folderAbs))
		{
			let name = scope String();
			entry.GetFileName(name);
			let s = new String();
			AppendLocator(s, folderLocator, name);
			outEntries.Add(s);
		}
		for (let entry in Directory.EnumerateDirectories(folderAbs))
		{
			let name = scope String();
			entry.GetFileName(name);
			let s = new String();
			AppendLocator(s, folderLocator, name);
			s.Append('/');
			outEntries.Add(s);
		}
	}

	// === IWatchableMount ===

	public IChangeSource ChangeSource
	{
		get
		{
			if (mChangeSource == null)
				mChangeSource = new FileSystemChangeSource(this);
			return mChangeSource;
		}
	}

	// === IWritableMount ===

	public Result<void, MountError> Save(StringView locator, Stream data)
	{
		let abs = scope String();
		ResolveAbsolute(locator, abs);

		// Create parent directory if needed.
		let parent = scope String();
		Path.GetDirectoryPath(abs, parent).IgnoreError();
		if (parent.Length > 0 && !Directory.Exists(parent))
		{
			if (Directory.CreateDirectory(parent) case .Err)
				return .Err(.IOError);
		}

		let stream = scope FileStream();
		if (stream.Create(abs, .Write) case .Err)
			return .Err(.IOError);

		// Copy `data` into the file. Caller still owns `data`.
		const int BufferSize = 4096;
		uint8[BufferSize] buffer = ?;
		while (true)
		{
			switch (data.TryRead(.(&buffer[0], BufferSize)))
			{
			case .Ok(let n):
				if (n == 0) return .Ok;
				if (stream.TryWrite(.(&buffer[0], n)) case .Err)
					return .Err(.IOError);
			case .Err:
				return .Err(.IOError);
			}
		}
	}

	public Result<void, MountError> Delete(StringView locator)
	{
		let abs = scope String();
		ResolveAbsolute(locator, abs);
		if (File.Exists(abs))
		{
			if (File.Delete(abs) case .Err)
				return .Err(.IOError);
			return .Ok;
		}
		if (Directory.Exists(abs))
		{
			if (Directory.DelTree(abs) case .Err)
				return .Err(.IOError);
			return .Ok;
		}
		return .Err(.NotFound);
	}

	public Result<void, MountError> Move(StringView srcLocator, StringView dstLocator)
	{
		let src = scope String();
		ResolveAbsolute(srcLocator, src);
		let dst = scope String();
		ResolveAbsolute(dstLocator, dst);

		// Ensure the destination's parent directory exists (OS rename does
		// not create intermediate directories).
		let parent = scope String();
		Path.GetDirectoryPath(dst, parent).IgnoreError();
		if (parent.Length > 0 && !Directory.Exists(parent))
		{
			if (Directory.CreateDirectory(parent) case .Err)
				return .Err(.IOError);
		}

		if (File.Exists(src))
		{
			if (File.Move(src, dst) case .Err)
				return .Err(.IOError);
			return .Ok;
		}
		if (Directory.Exists(src))
		{
			if (Directory.Move(src, dst) case .Err)
				return .Err(.IOError);
			return .Ok;
		}
		return .Err(.NotFound);
	}

	public Result<void, MountError> CreateDirectory(StringView locator)
	{
		let abs = scope String();
		ResolveAbsolute(locator, abs);
		if (Directory.Exists(abs))
			return .Ok;
		if (Directory.CreateDirectory(abs) case .Err)
			return .Err(.IOError);
		return .Ok;
	}

	// === Internal ===

	/// Resolves a mount-relative locator to an absolute filesystem path.
	/// Called by `FileSystemChangeSource` via `[Friend]`.
	private void ResolveAbsolute(StringView locator, String outPath)
	{
		outPath.Clear();
		outPath.Append(mRootPath);
		if (locator.Length > 0)
		{
			if (!outPath.EndsWith('/'))
				outPath.Append('/');
			outPath.Append(locator);
		}
	}

	private static void AppendLocator(String dst, StringView folder, StringView name)
	{
		dst.Append(folder);
		// `folder` is either empty or already ends with '/'.
		dst.Append(name);
	}
}
