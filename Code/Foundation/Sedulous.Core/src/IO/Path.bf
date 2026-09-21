using System;

namespace Sedulous.Core.IO;

/// UTF-8 path manipulation, on the forward slash.
///
/// Every query FILLS a string the caller owns rather than returning a view. That is the
/// Beef pattern, and it also removes a whole class of bug: a view has to represent "empty"
/// somehow, and a null view compares equal to "" only where the comparison null-checks
/// before it compares pointers. A filled string is just a string on every platform.
///
/// Only PathIsSeparator delegates to corlib. The rest deliberately do not, because
/// corlib's Path splits on VolumeSeparatorChar, which is ':' on Windows and '/' everywhere
/// else, so GetFileName("ns:local") answers "local" on Windows and "ns:local" on Linux.
/// These paths are logical, not host paths, and they have to mean one thing everywhere.
static
{
	public const char8 PathSeparator = '/';

	/// Both slashes count on both platforms, which is exactly what corlib does: its
	/// separator and its alternate are '\' and '/' on Windows, and the same pair the other
	/// way round elsewhere.
	public static bool PathIsSeparator(char8 c) => System.IO.Path.IsDirectorySeparatorChar(c);

	/// Absolute means rooted on THIS host's filesystem. On Windows that also covers a
	/// drive qualified root and a UNC share. A leading separator alone is drive relative
	/// there, but treating it as absolute keeps the POSIX contract and matches how the
	/// engine builds paths. PathJoin leans on this: an absolute second part must win
	/// rather than be appended to the first.
	///
	/// Not corlib's IsPathRooted, which calls "C:x" rooted without a separator after the
	/// colon. That is a drive-relative path, and joining onto it would put the result
	/// somewhere that depends on a per-drive working directory.
	public static bool PathIsAbsolute(StringView path)
	{
		if (path.IsEmpty)
			return false;
		if (PathIsSeparator(path[0]))
			return true; // a POSIX root, and a UNC path on Windows

		// A drive qualified root, "X:\..." or "X:/...". Checked on every platform rather
		// than under a conditional, so a path authored on Windows reads the same here.
		if ((path.Length >= 3) && (path[1] == ':') && PathIsSeparator(path[2]))
		{
			let drive = path[0];
			return ((drive >= 'A') && (drive <= 'Z')) || ((drive >= 'a') && (drive <= 'z'));
		}
		return false;
	}

	/// The final component, after the last separator.
	public static void PathFilename(StringView path, String outName)
	{
		outName.Clear();

		var start = 0;
		for (int i < path.Length)
		{
			if (PathIsSeparator(path[i]))
				start = i + 1;
		}
		outName.Append(StringView(path, start));
	}

	/// The extension including its dot, or empty.
	///
	/// A leading-dot name such as .gitignore is all name and no extension. corlib's
	/// GetExtension answers ".gitignore" for that, so it is not used here.
	public static void PathExtension(StringView path, String outExtension)
	{
		outExtension.Clear();

		let name = scope String();
		PathFilename(path, name);

		var dot = name.Length;
		for (int i < name.Length)
		{
			if (name[i] == '.')
				dot = i;
		}
		if ((dot == name.Length) || (dot == 0))
			return;
		outExtension.Append(StringView(name, dot));
	}

	/// The filename without its extension.
	public static void PathStem(StringView path, String outStem)
	{
		let name = scope String();
		PathFilename(path, name);
		let @extension = scope String();
		PathExtension(path, @extension);

		outStem.Clear();
		outStem.Append(StringView(name, 0, name.Length - @extension.Length));
	}

	/// Everything before the last separator, or empty if there is none.
	public static void PathParent(StringView path, String outParent)
	{
		outParent.Clear();

		var lastSeparator = path.Length;
		for (int i < path.Length)
		{
			if (PathIsSeparator(path[i]))
				lastSeparator = i;
		}
		if (lastSeparator == path.Length)
			return;
		outParent.Append(StringView(path, 0, lastSeparator));
	}

	/// Joins two paths with exactly one separator. An absolute second part wins outright.
	///
	/// Not corlib's Combine, which joins with the platform separator. These paths are
	/// stored and compared, so they use the forward slash on every platform.
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
