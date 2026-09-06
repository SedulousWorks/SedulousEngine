using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// The type id hash. Every stored object is keyed by one of these, so the function is part
/// of the FORMAT: changing it does not break a build, it silently orphans every asset
/// already written.
class TypeIdTests
{
	/// Pinned literals rather than a self consistent round trip. A test that only checks
	/// TypeIdOf(x) == TypeIdOf(x) passes just as happily after the hash has changed, which
	/// is the one thing worth catching here.
	[Test]
	public static void TheHashIsPinnedToKnownValues()
	{
		Test.Assert(TypeIdOf("Sedulous.Core.Tests.SerializableSample") == 0xE60C13FA3470374EUL);
		Test.Assert(TypeIdOf("Sedulous.Geometry.StaticMeshSource") == 0x76F881636413C3F1UL);
		Test.Assert(TypeIdOf("Sedulous.Geometry.SkinnedMeshSource") == 0xA28470900CAE793DUL);
		// The empty name is the FNV offset basis, untouched.
		Test.Assert(TypeIdOf("") == 0xCBF29CE484222325UL);
	}

	/// FNV depends on the multiply WRAPPING. Long names are what push it around the full
	/// 64 bits repeatedly, so this is where a checked multiply would trap.
	[Test]
	public static void ALongNameHashesWithoutTrapping()
	{
		let long = scope String();
		for (int i < 512)
			long.Append("Sedulous.Some.Deeply.Nested.Namespace.TypeName.");

		let hash = TypeIdOf(long);
		Test.Assert(hash != 0, "it produced something");
		Test.Assert(hash != 0xCBF29CE484222325UL, "and it is not still the offset basis");
	}

	/// Distinct names give distinct ids, including names that differ only in case or by a
	/// namespace separator. A collision here means two types share storage.
	[Test]
	public static void DistinctNamesGiveDistinctIds()
	{
		let names = scope String[](
			"Sedulous.Geometry.StaticMeshSource",
			"Sedulous.Geometry.SkinnedMeshSource",
			"Sedulous.Geometry.staticMeshSource",
			"Sedulous.GeometryStaticMeshSource",
			"Sedulous.Geometry.StaticMeshSourc",
			"Sedulous.Geometry.StaticMeshSourcee");

		for (int i < names.Count)
		{
			for (int j = i + 1; j < names.Count; j++)
			{
				Test.Assert(TypeIdOf(names[i]) != TypeIdOf(names[j]),
					scope $"'{names[i]}' and '{names[j]}' collided");
			}
		}
	}
}
