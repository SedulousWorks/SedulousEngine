using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Editor.Project;

/// Files and trees copied between directories, what was executable kept so: a player copied into
/// a dist must still start.
static class FileCopy
{
	/// A file copied between directories; the caller's names.
	public static bool CopyFile(StringView srcDir, StringView srcName, StringView dstDir, StringView dstName)
	{
		let src = PathJoin(srcDir, srcName, .. scope .());
		let bytes = scope List<uint8>();
		if (ReadFile(src, bytes) case .Err)
			return false;
		let dst = PathJoin(dstDir, dstName, .. scope .());
		CreateDirectory(PathParent(dst, .. scope .()));
		if (WriteFile(dst, bytes) case .Err)
			return false;
#if !BF_PLATFORM_WINDOWS
		// The bytes alone make a file nothing can run: a player copied into a dist would not
		// start. What was executable stays so.
		if (access(src.CStr(), cExecutable) == 0)
			MakeExecutable(dst);
#endif
		return true;
	}

	/// Marks the file at `path` executable (0755), as a build marks what it links; nothing on
	/// Windows, where the name says it.
	public static void MakeExecutable(StringView path)
	{
#if !BF_PLATFORM_WINDOWS
		chmod(scope String(path).CStr(), 493); // 0755
#endif
	}

#if !BF_PLATFORM_WINDOWS
	private const int32 cExecutable = 1; // X_OK

	[CLink]
	private static extern int32 access(char8* path, int32 mode);

	[CLink]
	private static extern int32 chmod(char8* path, uint32 mode);
#endif

	/// A directory tree copied, files overwritten.
	public static bool CopyTree(StringView src, StringView dst)
	{
		if (!CreateDirectory(dst))
			return false;
		bool ok = true;
		let names = scope List<(String name, bool isDirectory)>();
		ListDirectory(src, scope [&](name, isDirectory) => { names.Add((new String(name), isDirectory)); });
		for (let entry in names)
		{
			if (entry.isDirectory)
				ok = CopyTree(PathJoin(src, entry.name, .. scope .()), PathJoin(dst, entry.name, .. scope .())) && ok;
			else
				ok = CopyFile(src, entry.name, dst, entry.name) && ok;
			delete entry.name;
		}
		return ok;
	}
}
