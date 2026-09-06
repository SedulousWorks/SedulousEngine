using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

class PathTests
{
	[Test]
	public static void Queries()
	{
		Test.Assert(PathFilename("/a/b/c.txt", .. scope String()) == "c.txt");
		Test.Assert(PathFilename("noslash.dat", .. scope String()) == "noslash.dat");
		Test.Assert(PathExtension("/a/b/c.txt", .. scope String()) == ".txt");
		Test.Assert(PathExtension("/a/b/c", .. scope String()) == "");
		Test.Assert(PathExtension("/a/.hidden", .. scope String()) == "", "a dotfile is all name and no extension");
		Test.Assert(PathStem("/a/b/c.txt", .. scope String()) == "c");
		Test.Assert(PathParent("/a/b/c.txt", .. scope String()) == "/a/b");
		Test.Assert(PathParent("file", .. scope String()) == "");

		Test.Assert(PathIsAbsolute("/etc/hosts"));
		Test.Assert(!PathIsAbsolute("relative/path"));
	}

	/// Every query FILLS a string rather than returning a view, which is the Beef pattern
	/// and also removes the question of what an empty view is: there is no view. An empty
	/// answer is an empty string, and that reads the same on every platform and against
	/// every comparison overload.
	[Test]
	public static void AnEmptyAnswerIsAnEmptyString()
	{
		let name = scope String("stale contents");
		PathFilename("/a/b/", name);
		Test.Assert(name.IsEmpty, "a trailing separator leaves no filename");
		Test.Assert(name == "");
		Test.Assert(name == StringView());

		let @extension = scope String("stale");
		PathExtension("/a/b/c", @extension);
		Test.Assert(@extension.IsEmpty);

		let parent = scope String("stale");
		PathParent("file", parent);
		Test.Assert(parent.IsEmpty);

		let stem = scope String("stale");
		PathStem("", stem);
		Test.Assert(stem.IsEmpty);
	}

	/// A trailing separator, both separators, and the degenerate inputs. A filename loop
	/// that stops at the first separator rather than the last passes the simple cases.
	[Test]
	public static void QueryEdgeCases()
	{
		Test.Assert(PathParent("/a/b/", .. scope String()) == "/a/b");
		Test.Assert(PathFilename("", .. scope String()) == "");
		Test.Assert(PathParent("", .. scope String()) == "");
		Test.Assert(PathExtension("", .. scope String()) == "");
		Test.Assert(PathStem("", .. scope String()) == "");

		// Deep paths: the last separator wins, not the first.
		Test.Assert(PathFilename("/one/two/three/four.tar.gz", .. scope String()) == "four.tar.gz");
		Test.Assert(PathExtension("/one/two/three/four.tar.gz", .. scope String()) == ".gz", "the last dot wins");
		Test.Assert(PathStem("/one/two/three/four.tar.gz", .. scope String()) == "four.tar");

		// A backslash counts as a separator whatever the host is, which is what corlib's
		// IsDirectorySeparatorChar says on both platforms.
		Test.Assert(PathFilename(@"a\b\c.txt", .. scope String()) == "c.txt");
		Test.Assert(PathParent(@"a\b\c.txt", .. scope String()) == @"a\b");

		// A dot in a directory name is not the file's extension.
		Test.Assert(PathExtension("/a.b/c", .. scope String()) == "");
		Test.Assert(PathStem("/a.b/c", .. scope String()) == "c");

		Test.Assert(!PathIsAbsolute(""));
		Test.Assert(PathIsSeparator('/'));
		Test.Assert(PathIsSeparator('\\'));
		Test.Assert(!PathIsSeparator('.'));
	}

	/// A colon is NOT a separator here, on any platform. corlib's Path splits on
	/// VolumeSeparatorChar, which is ':' on Windows and '/' elsewhere, so delegating these
	/// would make "ns:local" answer "local" on Windows and "ns:local" on Linux. These are
	/// logical paths, and they have to mean one thing everywhere.
	[Test]
	public static void AColonIsNotASeparator()
	{
		Test.Assert(PathFilename("ns:local", .. scope String()) == "ns:local");
		Test.Assert(PathParent("ns:local", .. scope String()) == "");
		Test.Assert(PathFilename("a/ns:local", .. scope String()) == "ns:local");
	}

	/// A drive qualified root is absolute on every platform, so a path authored on
	/// Windows is read the same way here.
	[Test]
	public static void DriveQualifiedRootsAreAbsoluteEverywhere()
	{
		Test.Assert(PathIsAbsolute(@"C:\Windows"));
		Test.Assert(PathIsAbsolute("C:/Windows"));
		Test.Assert(PathIsAbsolute("c:/windows"));

		// A drive with no separator is drive RELATIVE, not absolute: where it lands
		// depends on a per-drive working directory.
		Test.Assert(!PathIsAbsolute("C:Windows"));
		Test.Assert(!PathIsAbsolute("C:"));
		Test.Assert(!PathIsAbsolute("1:/x"), "not a drive letter");

		// A UNC share, and the POSIX root.
		Test.Assert(PathIsAbsolute(@"\\server\share"));
		Test.Assert(PathIsAbsolute("/etc"));
	}

	[Test]
	public static void Join()
	{
		Test.Assert(PathJoin("/a/b", "c.txt", .. scope String()) == "/a/b/c.txt");
		Test.Assert(PathJoin("/a/b/", "c.txt", .. scope String()) == "/a/b/c.txt",
			"an existing separator must not be doubled");
		Test.Assert(PathJoin("", "c.txt", .. scope String()) == "c.txt");
		Test.Assert(PathJoin("/a/b", "/absolute", .. scope String()) == "/absolute",
			"an absolute second part wins outright");

		// The forward slash on every platform, not corlib's platform separator: these
		// paths are stored and compared.
		Test.Assert(PathJoin(@"a\b", "c", .. scope String()) == @"a\b/c");
		Test.Assert(PathJoin("/a/b", @"C:\x", .. scope String()) == @"C:\x", "an absolute drive path wins too");
	}

	/// Join writes the whole result rather than appending to what it was handed, so a
	/// reused string does not accumulate.
	[Test]
	public static void JoinReplacesTheOutput()
	{
		let joined = scope String("stale contents");
		PathJoin("/a", "b", joined);
		Test.Assert(joined == "/a/b");

		PathJoin("/c", "d", joined);
		Test.Assert(joined == "/c/d");
	}
}
