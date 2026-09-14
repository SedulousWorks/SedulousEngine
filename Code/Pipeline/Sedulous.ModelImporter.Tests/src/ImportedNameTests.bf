using System;
using Sedulous.Model;

namespace Sedulous.ModelImporter.Tests;

/// What an import calls the things it creates.
///
/// The names become FILE NAMES on disk, and they are also the keys the review dialog's
/// decisions are matched on, so both halves are pinned here.
class ImportedNameTests
{
	private static void CheckTexture(ModelTexture texture, int index, StringView expected)
	{
		let name = scope String();
		ImportedNames.ForTexture(texture, index, name);
		Test.Assert(name == expected, scope $"texture name was '{name}'");
	}

	private static void CheckAsset(StringView authored, StringView fallback, int index,
		StringView expected)
	{
		let name = scope String();
		ImportedNames.ForAsset(authored, fallback, index, name);
		Test.Assert(name == expected, scope $"asset name was '{name}'");
	}

	/// The FILE STEM comes first: an authored image name can disagree with the file it came
	/// from, and the file is what a person sees on disk and searches for.
	[Test]
	public static void ATextureIsNamedAfterItsFileThenItsAuthoredName()
	{
		let named = scope ModelTexture();
		named.Name.Set("BaseColor");
		CheckTexture(named, 0, "BaseColor");

		let fromUri = scope ModelTexture();
		fromUri.Uri.Set("textures/Default_albedo.jpg");
		CheckTexture(fromUri, 3, "Default_albedo");

		// An embedded image with no identity at all falls back to its index.
		CheckTexture(scope ModelTexture(), 7, "tex.7");
	}

	[Test]
	public static void ASubAssetKeepsItsAuthoredNameSanitised()
	{
		CheckAsset("Material_MR", "mat", 0, "Material_MR");
		CheckAsset("mesh_helmet_LP", "mesh", 3, "mesh_helmet_LP");
		// Path hostile characters heal, because the name becomes an envelope file name.
		CheckAsset("body/armor:v2", "mesh", 0, "body_armor_v2");
		CheckAsset("", "anim", 4, "anim.4");
	}

	/// A skin with no name of its own is simply "skeleton", which is also what the plan lists,
	/// so a decision about it reaches the instance the import claims.
	[Test]
	public static void ASkeletonIsNamedAfterItsSkin()
	{
		let unnamed = scope ModelSkin();
		let name = scope String();
		ImportedNames.ForSkeleton(unnamed, name);
		Test.Assert(name == "skeleton");

		let named = scope ModelSkin();
		named.Name.Set("Armature");
		let namedOut = scope String();
		ImportedNames.ForSkeleton(named, namedOut);
		Test.Assert(namedOut == "Armature");
	}
}
