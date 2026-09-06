using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

class PathTests
{
	[Test]
	public static void Queries()
	{
		Test.Assert(PathFilename("/a/b/c.txt") == "c.txt");
		Test.Assert(PathFilename("noslash.dat") == "noslash.dat");
		Test.Assert(PathExtension("/a/b/c.txt") == ".txt");
		Test.Assert(PathExtension("/a/b/c") == "");
		Test.Assert(PathExtension("/a/.hidden") == "", "a dotfile is all name and no extension");
		Test.Assert(PathStem("/a/b/c.txt") == "c");
		Test.Assert(PathParent("/a/b/c.txt") == "/a/b");
		Test.Assert(PathParent("file") == "");

		Test.Assert(PathIsAbsolute("/etc/hosts"));
		Test.Assert(!PathIsAbsolute("relative/path"));
	}

	/// The queries return views INTO the path, so none of them allocates and each one has
	/// to get its offsets right rather than leaning on a copy.
	[Test]
	public static void QueriesReturnViewsIntoTheInput()
	{
		let path = "/a/b/c.txt";
		let name = PathFilename(path);
		Test.Assert(name.Ptr == path.Ptr + 5, "the filename must alias the path, not copy it");
		Test.Assert(PathExtension(path).Ptr == path.Ptr + 6);
		Test.Assert(PathStem(path).Ptr == path.Ptr + 5);
		Test.Assert(PathParent(path).Ptr == path.Ptr);
	}

	/// A trailing separator, both separators, and the degenerate inputs. A filename loop
	/// that stops at the first separator rather than the last passes the simple cases.
	[Test]
	public static void QueryEdgeCases()
	{
		Test.Assert(PathFilename("/a/b/") == "", "a trailing separator leaves no filename");
		Test.Assert(PathParent("/a/b/") == "/a/b");
		Test.Assert(PathFilename("") == "");
		Test.Assert(PathParent("") == "");
		Test.Assert(PathExtension("") == "");
		Test.Assert(PathStem("") == "");

		// Deep paths: the last separator wins, not the first.
		Test.Assert(PathFilename("/one/two/three/four.tar.gz") == "four.tar.gz");
		Test.Assert(PathExtension("/one/two/three/four.tar.gz") == ".gz", "the last dot wins");
		Test.Assert(PathStem("/one/two/three/four.tar.gz") == "four.tar");

		// A backslash counts as a separator whatever the host is.
		Test.Assert(PathFilename(@"a\b\c.txt") == "c.txt");
		Test.Assert(PathParent(@"a\b\c.txt") == @"a\b");

		// A dot in a directory name is not the file's extension.
		Test.Assert(PathExtension("/a.b/c") == "");
		Test.Assert(PathStem("/a.b/c") == "c");

		Test.Assert(!PathIsAbsolute(""));
		Test.Assert(PathIsSeparator('/'));
		Test.Assert(PathIsSeparator('\\'));
		Test.Assert(!PathIsSeparator('.'));
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
