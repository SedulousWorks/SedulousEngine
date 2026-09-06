using System;
using System.Collections;
using Sedulous.Core.IO;

namespace Sedulous.VFS;

/// A scheme mount table.
///
/// A path is scheme://locator: the scheme picks a mounted backend and the locator, which
/// carries no scheme of its own, is handed to it. Schemeless paths are rejected rather
/// than guessed at, so a missing mount is an error at the call that made it.
///
/// It is a router, so it advertises no capabilities of its own. Ask a specific mount:
/// GetMount("project") as IWritableFileSystem.
///
/// Mounts are NOT owned. A backend must outlive the table it is mounted in.
class VirtualFileSystem : IFileSystem
{
	private const String cSchemeSeparator = "://";

	private struct MountPoint : IDisposable
	{
		public String Scheme;
		public IFileSystem Backend;

		public void Dispose() mut
		{
			delete Scheme;
			Scheme = null;
		}
	}

	private List<MountPoint> mMounts = new .() ~ delete _;

	public ~this()
	{
		for (var mount in ref mMounts)
			mount.Dispose();
	}

	/// Mounts a backend under a scheme, so Mount("project", fs) routes "project://...".
	/// Mounting a scheme twice replaces the first, which is how a host swaps a mount.
	public void Mount(StringView scheme, IFileSystem backend)
	{
		for (int i < mMounts.Count)
		{
			if (mMounts[i].Scheme == scheme)
			{
				mMounts[i].Backend = backend;
				return;
			}
		}
		mMounts.Add(MountPoint() { Scheme = new String(scheme), Backend = backend });
	}

	/// Removes a mount. The backend itself is untouched, since it was never owned.
	public bool Unmount(StringView scheme)
	{
		for (int i < mMounts.Count)
		{
			if (mMounts[i].Scheme == scheme)
			{
				var mount = mMounts[i];
				mount.Dispose();
				mMounts.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	public int MountCount => mMounts.Count;

	/// The backend registered for a scheme, or null.
	public IFileSystem GetMount(StringView scheme)
	{
		for (let mount in mMounts)
		{
			if (mount.Scheme == scheme)
				return mount.Backend;
		}
		return null;
	}

	public IStream Open(StringView path, FileMode mode)
	{
		if (!SplitScheme(path, let scheme, let locator))
			return null;

		let backend = GetMount(scheme);
		return (backend != null) ? backend.Open(locator, mode) : null;
	}

	public bool Exists(StringView path)
	{
		if (!SplitScheme(path, let scheme, let locator))
			return false;

		let backend = GetMount(scheme);
		return (backend != null) && backend.Exists(locator);
	}

	/// Splits "scheme://locator". False when there is no separator, since a path without a
	/// scheme names no mount and guessing one would route it somewhere arbitrary.
	public static bool SplitScheme(StringView path, out StringView scheme, out StringView locator)
	{
		scheme = default;
		locator = default;

		let at = path.IndexOf(cSchemeSeparator);
		if (at < 0)
			return false;

		scheme = .(path, 0, at);
		locator = .(path, at + cSchemeSeparator.Length);
		return true;
	}
}
