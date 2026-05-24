namespace Sedulous.Editor.Core;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// Editor-side bundle for a registered scheme: the mount that serves bytes,
/// the index that maps GUIDs to URIs, the URI scheme they share, and an
/// optional locator where the index is persisted within the mount.
///
/// The asset browser's tree and content adapters drive off `List<MountEntry>`.
/// EditorApplication is responsible for creating entries for builtin/project
/// schemes and any user-mounted ones, and adding them to
/// `EditorContext.MountEntries`.
///
/// The entry does not own the mount or index - those have their own lifetimes
/// managed by the application. `MountEntry` is just a co-locating view.
class MountEntry
{
	/// URI scheme this entry is registered under (e.g. "builtin", "project").
	public String Scheme = new .() ~ delete _;

	/// Byte source for this scheme. Never null.
	public IMount Mount;

	/// GUID -> URI map for this scheme. May be null if the entry doesn't track identity.
	public IResourceIndex Index;

	/// Locator inside `Mount` where the index is persisted. Empty when the
	/// index is in-memory only.
	public String IndexLocator = new .() ~ delete _;

	/// When true, the entry can't be unmounted by the user (builtin / project).
	public bool IsLocked;

	/// When true, this entry owns the Mount and Index and deletes them on destruction.
	/// Dynamically added mounts (e.g., from the asset browser) set this to true.
	/// Static mounts (builtin, project) are owned by EditorApplication fields.
	public bool OwnsResources;

	public this(StringView scheme, IMount mount, IResourceIndex index, StringView indexLocator = "", bool isLocked = false)
	{
		Scheme.Set(scheme);
		Mount = mount;
		Index = index;
		IndexLocator.Set(indexLocator);
		IsLocked = isLocked;
	}

	public ~this()
	{
		if (OwnsResources)
		{
			if (Mount != null) delete Mount;
			if (Index != null) delete Index;
		}
	}
}

/// Static helpers for going between mount-relative locators and absolute
/// filesystem paths against a list of mount entries.
///
/// The asset browser deals in absolute filesystem paths (because it walks
/// directories with `Directory.Enumerate*`); the resource system deals in
/// URIs. These helpers bridge the two for editor code that has an absolute
/// path in hand and needs to open it through the right mount.
///
/// Only `FileSystemMount`-backed entries can be resolved this way - a pak or
/// remote mount has no absolute filesystem path, and `TryResolveAbsolute`
/// will simply skip it. That's intentional: code that calls into this is
/// implicitly disk-only.
public static class MountResolver
{
	/// Walks `entries` for a FileSystemMount whose root path prefixes
	/// `absolutePath`. On match, returns the mount and the mount-relative
	/// locator. Returns false if no entry matches.
	public static bool TryResolveAbsolute(List<MountEntry> entries, StringView absolutePath,
		out IMount mount, String outLocator)
	{
		mount = null;
		outLocator.Clear();
		if (entries == null) return false;

		let normalized = scope String(absolutePath);
		normalized.Replace('\\', '/');

		for (let entry in entries)
		{
			let fsMount = entry.Mount as FileSystemMount;
			if (fsMount == null) continue;

			let root = scope String(fsMount.RootPath);
			root.Replace('\\', '/');
			if (!root.EndsWith('/'))
				root.Append('/');

			if (normalized.StartsWith(root, .OrdinalIgnoreCase))
			{
				mount = entry.Mount;
				outLocator.Set(normalized.Substring(root.Length));
				return true;
			}
		}
		return false;
	}

	/// Same as `TryResolveAbsolute`, but additionally requires the mount to
	/// be writable. Useful for save flows.
	public static bool TryResolveAbsoluteWritable(List<MountEntry> entries, StringView absolutePath,
		out IWritableMount mount, String outLocator)
	{
		mount = null;
		IMount asMount;
		if (!TryResolveAbsolute(entries, absolutePath, out asMount, outLocator))
			return false;
		mount = asMount as IWritableMount;
		return mount != null;
	}

	/// Resolves an absolute filesystem path to a `scheme://locator` URI usable
	/// with `ResourceSystem.LoadResource`. Returns false if no mount entry's
	/// root prefixes the path.
	public static bool TryResolveAbsoluteToUri(List<MountEntry> entries, StringView absolutePath,
		String outUri)
	{
		outUri.Clear();
		if (entries == null) return false;

		IMount mount = null;
		let locator = scope String();
		if (!TryResolveAbsolute(entries, absolutePath, out mount, locator))
			return false;

		for (let entry in entries)
		{
			if (entry.Mount === mount)
			{
				outUri.AppendF("{}://{}", entry.Scheme, locator);
				return true;
			}
		}
		return false;
	}

	/// Reverse of `TryResolveAbsoluteToUri`. Parses a `scheme://locator` URI
	/// and joins the locator onto the matching disk-backed mount's root path.
	/// Returns false if the URI is malformed, no entry has the scheme, or the
	/// entry's mount isn't a `FileSystemMount`.
	public static bool TryResolveUriToAbsolute(List<MountEntry> entries, StringView uri,
		String outAbsolutePath)
	{
		outAbsolutePath.Clear();
		if (entries == null) return false;

		let sep = uri.IndexOf("://");
		if (sep <= 0) return false;
		let scheme = uri.Substring(0, sep);
		let locator = uri.Substring(sep + 3);

		for (let entry in entries)
		{
			if (StringView(entry.Scheme) == scheme)
			{
				let fsMount = entry.Mount as FileSystemMount;
				if (fsMount == null) return false;
				System.IO.Path.InternalCombine(outAbsolutePath, fsMount.RootPath, scope String(locator));
				return true;
			}
		}
		return false;
	}
}
