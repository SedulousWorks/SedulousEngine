using System;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// The path work every importer builds on: the lowercase extension routing keys on, and the
/// name and stem an instance is called after.
class ImportPathTests
{
	private static StringView Extension(StringView path)
	{
		let result = new:ScopedAlloc! String();
		ImportPaths.ExtensionLower(path, result);
		return result;
	}

	[Test]
	public static void TheExtensionIsLowercasedAndDotless()
	{
		Test.Assert(Extension("/a/b/Foo.PNG") == "png");
		Test.Assert(Extension("C:\\art\\thing.Jpeg") == "jpeg");
		Test.Assert(Extension("noext") == "");
		// The dot is in a DIRECTORY, not the file, so there is still no extension.
		Test.Assert(Extension("/dotted.dir/noext") == "");
	}

	[Test]
	public static void TheFileNameAndStemHandleBothSeparators()
	{
		Test.Assert(ImportPaths.FileNameOf("/a/b/foo.png") == "foo.png");
		Test.Assert(ImportPaths.FileNameOf("C:\\a\\b.png") == "b.png");
		Test.Assert(ImportPaths.FileNameOf("bare.png") == "bare.png");

		Test.Assert(ImportPaths.StemOf("foo.png") == "foo");
		Test.Assert(ImportPaths.StemOf("foo") == "foo");
	}
}
