using System;

namespace Sedulous.Core.IO;

/// UTF-8 path manipulation, on the POSIX separator.
///
/// The queries are non-owning: each returns a view into the path it was given, so none of
/// them allocates. Only PathJoin builds anything, and it fills a string the caller owns.
static
{
	public const char8 PathSeparator = '/';

	public static bool PathIsSeparator(char8 c) => (c == '/') || (c == '\\');

	/// Absolute means rooted on THIS host's filesystem. On Windows that also covers a
	/// drive qualified root and a UNC share. A leading separator alone is drive relative
	/// there, but treating it as absolute keeps the POSIX contract and matches how the
	/// engine builds paths. PathJoin leans on this: an absolute second part must win
	/// rather than be appended to the first.
	public static bool PathIsAbsolute(StringView path)
	{
		if (path.IsEmpty)
			return false;
		if (PathIsSeparator(path[0]))
			return true; // a POSIX root, and a UNC path on Windows

#if BF_PLATFORM_WINDOWS
		// A drive qualified root, "X:\..." or "X:/...".
		if ((path.Length >= 3) && (path[1] == ':') && PathIsSeparator(path[2]))
		{
			let drive = path[0];
			return ((drive >= 'A') && (drive <= 'Z')) || ((drive >= 'a') && (drive <= 'z'));
		}
#endif
		return false;
	}

	/// The final component, after the last separator.
	public static StringView PathFilename(StringView path)
	{
		var start = 0;
		for (int i < path.Length)
		{
			if (PathIsSeparator(path[i]))
				start = i + 1;
		}
		return .(path, start, path.Length - start);
	}

	/// The extension including its dot, or empty. A leading-dot name such as .gitignore
	/// is all name and no extension.
	///
	/// "Empty" is a zero length view INTO the path, never a null one. A null view compares
	/// equal to "" only where the comparison happens to null-check first, so returning one
	/// makes a caller's == depend on which overload it picked and on which corlib it was
	/// built against. A view anchored in the input has one answer everywhere.
	public static StringView PathExtension(StringView path)
	{
		let name = PathFilename(path);
		var dot = name.Length;
		for (int i < name.Length)
		{
			if (name[i] == '.')
				dot = i;
		}
		if ((dot == name.Length) || (dot == 0))
			return .(name, name.Length, 0);
		return .(name, dot, name.Length - dot);
	}

	/// The filename without its extension.
	public static StringView PathStem(StringView path)
	{
		let name = PathFilename(path);
		let @extension = PathExtension(path);
		return .(name, 0, name.Length - @extension.Length);
	}

	/// Everything before the last separator, or empty if there is none. Empty is a zero
	/// length view into the path rather than a null one, as in PathExtension.
	public static StringView PathParent(StringView path)
	{
		var lastSeparator = path.Length;
		for (int i < path.Length)
		{
			if (PathIsSeparator(path[i]))
				lastSeparator = i;
		}
		if (lastSeparator == path.Length)
			return .(path, 0, 0);
		return .(path, 0, lastSeparator);
	}

	/// Joins two paths with exactly one separator. An absolute second part wins outright.
	public static void PathJoin(StringView a, StringView b, String outPath)
	{
		outPath.Clear();
		if (a.IsEmpty || PathIsAbsolute(b))
		{
			outPath.Append(b);
			return;
		}

		outPath.Append(a);
		if (!PathIsSeparator(a[a.Length - 1]))
			outPath.Append(PathSeparator);
		outPath.Append(b);
	}
}
