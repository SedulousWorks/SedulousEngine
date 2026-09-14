using System;

namespace Sedulous.ModelImporter.Tests;

/// Reading an authored level of detail suffix off a mesh name.
class LodSuffixTests
{
	[Test]
	public static void ASuffixNamesItsLevelAndItsBaseWhateverTheCase()
	{
		let @base = scope String();
		Test.Assert(LodSuffix.Parse("Foo_LOD1", @base) == 1);
		Test.Assert(@base == "Foo");
		Test.Assert(LodSuffix.Parse("Rock_lod2", @base) == 2);
		Test.Assert(@base == "Rock");
		Test.Assert(LodSuffix.Parse("Wall_Lod12", @base) == 12);
		Test.Assert(@base == "Wall");
	}

	/// NOUGHT means a plain mesh. Level nought spelled out is one too: the base of a chain
	/// spells itself plainly, so "Foo_LOD0" IS a base rather than a level of some other "Foo"
	/// that may not even exist.
	[Test]
	public static void AnythingElseIsAPlainName()
	{
		let @base = scope String();
		Test.Assert(LodSuffix.Parse("Foo", @base) == 0);
		Test.Assert(LodSuffix.Parse("Foo_LOD0", @base) == 0);
		Test.Assert(LodSuffix.Parse("Foo_LOD", @base) == 0);
		Test.Assert(LodSuffix.Parse("LOD1", @base) == 0);
		Test.Assert(LodSuffix.Parse("Foo_MOD1", @base) == 0);
	}
}
