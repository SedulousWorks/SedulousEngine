using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// What assets carry when dragged: the payload they make, read back whole; a target that takes
/// some types taking one or naming why not (several, a type it does not take); anything else not an
/// asset. Then what Sedulous adds so each behaviour has a test: the effects a drag allows, a payload
/// filled over an older one, a name with a line break, a payload of the asset's type with a value
/// that is no asset, a target that names a type in full or short while an instance names it in
/// full, a reason that replaces what the string held, and for a run: its order and names kept
/// whatever they hold, Read taking the first, its label, the list ReadAll fills, and a run not as
/// Payload writes it not read.
class AssetDragTests
{
	private static readonly Guid sId = Guid(0xabcd, 0x1234, 0x5678, 1, 2, 3, 4, 5, 6, 7, 8);
	private static readonly Guid sOther = Guid(0x2222, 0x2222, 0x2222, 2, 2, 2, 2, 2, 2, 2, 2);
	private static readonly Guid sThird = Guid(0x3333, 0x3333, 0x3333, 3, 3, 3, 3, 3, 3, 3, 3);

	/// The asset type with `text` as its value, as no source but a test writes it.
	private static void SetText(DragPayload payload, StringView text)
	{
		payload.Type.Set(AssetDrag.cType);
		payload.Value.Dispose();
		payload.Value = TextVariant(text);
	}

	/// One asset's block as Payload writes it: guid, type and the name's length on lines of their
	/// own, then the name and a line break.
	private static void AppendBlock(String text, Guid id, StringView typeName, StringView name)
	{
		id.ToString(text);
		text.AppendF("\n{}\n{}\n{}\n", typeName, name.Length, name);
	}

	[Test]
	public static void PayloadCarriesTheAssetsGuidTypeAndNameAndATargetTakesItByType()
	{
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "MaterialAsset", "Wood", payload);
		Test.Assert(payload.Type == AssetDrag.cType);
		Test.Assert(payload.Label == "Wood");

		let read = scope AssetDrag();
		Test.Assert(AssetDrag.Read(payload, read));
		Test.Assert(read.Id == sId);
		Test.Assert(read.TypeName == "MaterialAsset");
		Test.Assert(read.Name == "Wood");

		let why = scope String();
		String[1] materials = .("MaterialAsset");
		Test.Assert(AssetDrag.Takes(payload, materials, read, why));
		Test.Assert(AssetDrag.Takes(payload, Span<String>(), read, why)); // a target that takes any
		String[2] meshes = .("StaticMeshAsset", "SkinnedMeshAsset");
		Test.Assert(!AssetDrag.Takes(payload, meshes, read, why));
		Test.Assert(why == "Wood is a MaterialAsset, not one this takes");

		let text = scope DragPayload();
		text.Type.Set("text");
		text.Value = TextVariant("hello");
		Test.Assert(!AssetDrag.Read(text, read));
		Test.Assert(!AssetDrag.Takes(text, Span<String>(), read, why));
		Test.Assert(why == "Not an asset");
	}

	/// Assets are linked or copied where they are dropped, or moved, as into a group; one or a run.
	[Test]
	public static void PayloadAllowsLinkCopyAndMove()
	{
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "MaterialAsset", "Wood", payload);
		Test.Assert(payload.Allowed == (DropEffectsLink | DropEffectsCopy | DropEffectsMove));

		AssetDrag[2] assets = .(scope .(sId, "MaterialAsset", "Wood"), scope .(sOther, "TextureAsset", "Brick"));
		AssetDrag.Payload(assets, payload);
		Test.Assert(payload.Allowed == (DropEffectsLink | DropEffectsCopy | DropEffectsMove));
	}

	/// A source fills the request's payload, whatever it held: the asset replaces it whole.
	[Test]
	public static void PayloadReplacesWhatThePayloadHeld()
	{
		let payload = scope DragPayload();
		payload.Type.Set("text");
		payload.Value = TextVariant("old");
		payload.Label.Set("old label");
		AssetDrag.Payload(sId, "TextureAsset", "Grass", payload);
		Test.Assert(payload.Type == AssetDrag.cType);
		Test.Assert(payload.Label == "Grass");
		let read = scope AssetDrag();
		Test.Assert(AssetDrag.Read(payload, read));
		Test.Assert(read.Name == "Grass");
	}

	/// The name is whatever follows the type: a line break in it, or none at all, reads back.
	[Test]
	public static void NameWithALineBreakOrEmptyReadsBack()
	{
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "Sedulous.Materials.MaterialAsset", "two\nlines", payload);
		let read = scope AssetDrag();
		Test.Assert(AssetDrag.Read(payload, read));
		Test.Assert(read.TypeName == "Sedulous.Materials.MaterialAsset");
		Test.Assert(read.Name == "two\nlines");

		AssetDrag.Payload(sId, "MaterialAsset", "", payload);
		Test.Assert(AssetDrag.Read(payload, read));
		Test.Assert(read.TypeName == "MaterialAsset");
		Test.Assert(read.Name.IsEmpty);
	}

	/// Only the asset type carries an asset, and only with the value the asset makes; a payload
	/// read as none leaves what was read before as it was.
	[Test]
	public static void PayloadOfAnotherTypeOrValueIsNotRead()
	{
		let read = scope AssetDrag();
		read.Id = sId;
		read.TypeName.Set("MaterialAsset");
		read.Name.Set("Wood");

		// The asset's value under another type.
		let other = scope DragPayload();
		AssetDrag.Payload(Guid.Create(), "TextureAsset", "Grass", other);
		other.Type.Set("text");
		Test.Assert(!AssetDrag.Read(other, read));

		// The asset's type with a value that is no text, text with no guid where one goes, text too short
		// for one, and a guid with no type; each in the run's form, so only that part is wrong.
		let wrong = scope DragPayload();
		wrong.Type.Set(AssetDrag.cType);
		wrong.Value = System.Variant.Create((uint64)7);
		Test.Assert(!AssetDrag.Read(wrong, read));
		SetText(wrong, "1\nzzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz\nTextureAsset\n5\nGrass\n"); // a guid's length, not a guid
		Test.Assert(!AssetDrag.Read(wrong, read));
		SetText(wrong, "1\nshort\nTextureAsset\n5\nGrass\n");
		Test.Assert(!AssetDrag.Read(wrong, read));
		let noType = scope String("1\n");
		Guid.Create().ToString(noType);
		noType.Append("\nTextureAsset");
		SetText(wrong, noType);
		Test.Assert(!AssetDrag.Read(wrong, read));

		Test.Assert(read.Id == sId);
		Test.Assert(read.TypeName == "MaterialAsset");
		Test.Assert(read.Name == "Wood");
	}

	/// An instance names its type in full; a target takes it by its full or its short name, and a
	/// refusal names the short one.
	[Test]
	public static void TargetTakesAFullTypeNameByItsFullOrShortName()
	{
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "Sedulous.Geometry.Pipeline.StaticMeshAsset", "crate", payload);
		let read = scope AssetDrag();
		let why = scope String();
		String[2] byShort = .("SkinnedMeshAsset", "StaticMeshAsset");
		Test.Assert(AssetDrag.Takes(payload, byShort, read, why));
		Test.Assert(read.Id == sId);
		Test.Assert(read.Name == "crate");
		String[1] byFull = .("Sedulous.Geometry.Pipeline.StaticMeshAsset");
		Test.Assert(AssetDrag.Takes(payload, byFull, read, why));
		String[1] materials = .("MaterialAsset");
		Test.Assert(!AssetDrag.Takes(payload, materials, read, why));
		Test.Assert(why == "crate is a StaticMeshAsset, not one this takes");
	}

	/// A reason replaces what the string held, as a target's one string is reused drag after drag.
	[Test]
	public static void ReasonReplacesWhatTheStringHeld()
	{
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "MaterialAsset", "Wood", payload);
		let read = scope AssetDrag();
		let why = scope String("an older reason");
		String[1] meshes = .("StaticMeshAsset");
		Test.Assert(!AssetDrag.Takes(payload, meshes, read, why));
		Test.Assert(why == "Wood is a MaterialAsset, not one this takes");

		let text = scope DragPayload();
		text.Type.Set("text");
		text.Value = TextVariant("hello");
		Test.Assert(!AssetDrag.Takes(text, meshes, read, why));
		Test.Assert(why == "Not an asset");
	}

	/// Raptor's: several assets travel in order, labelled by their count; a target of one refuses
	/// them, saying why, with the first still read (an asset: a slot refuses rather than ignores it).
	[Test]
	public static void SeveralAssetsTravelInOrderLabelledByTheirCountATargetOfOneRefusesThem()
	{
		AssetDrag[2] assets = .(scope .(sId, "MaterialAsset", "Wood"), scope .(sOther, "TextureAsset", "Brick"));
		let payload = scope DragPayload();
		AssetDrag.Payload(assets, payload);
		Test.Assert(payload.Label == "2 assets");
		let all = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(all); }
		Test.Assert(AssetDrag.ReadAll(payload, all));
		Test.Assert(all.Count == 2);
		Test.Assert(all[1].Id == sOther);
		Test.Assert(all[1].Name == "Brick");

		let first = scope AssetDrag();
		let why = scope String();
		Test.Assert(!AssetDrag.Takes(payload, Span<String>(), first, why));
		Test.Assert(why == "This takes one asset");
		Test.Assert(first.Id == sId);
	}

	/// A run reads back whole and in order, each name as it was: line breaks in it, one that reads
	/// like a block of its own, or none at all.
	[Test]
	public static void ARunReadsBackInOrderWhateverItsNamesHold()
	{
		let lookalike = scope String("1\n");
		AppendBlock(lookalike, sOther, "TextureAsset", "Brick"); // a whole payload as a name
		AssetDrag[3] assets = .(scope .(sId, "Sedulous.Materials.MaterialAsset", "two\nlines, \u{e9}\n"),
			scope .(sOther, "TextureAsset", lookalike), scope .(sThird, "MeshAsset", ""));
		let payload = scope DragPayload();
		AssetDrag.Payload(assets, payload);
		Test.Assert(payload.Type == AssetDrag.cType);
		Test.Assert(payload.Label == "3 assets");

		let all = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(all); }
		Test.Assert(AssetDrag.ReadAll(payload, all));
		Test.Assert(all.Count == 3);
		for (int i < 3)
		{
			Test.Assert(all[i].Id == assets[i].Id);
			Test.Assert(all[i].TypeName == assets[i].TypeName);
			Test.Assert(all[i].Name == assets[i].Name);
		}

		// One asset's payload is a run of one.
		AssetDrag.Payload(sId, "MaterialAsset", "Wood", payload);
		Test.Assert(AssetDrag.ReadAll(payload, all));
		Test.Assert(all.Count == 1);
		Test.Assert(all[0].Id == sId);
		Test.Assert(all[0].Name == "Wood");
	}

	/// Read takes a run's first; Takes refuses the run, so a target of one asset only takes one.
	[Test]
	public static void ReadTakesARunsFirst()
	{
		AssetDrag[2] assets = .(scope .(sId, "MaterialAsset", "Wood"), scope .(sOther, "TextureAsset", "Brick"));
		let payload = scope DragPayload();
		AssetDrag.Payload(assets, payload);
		let read = scope AssetDrag();
		Test.Assert(AssetDrag.Read(payload, read));
		Test.Assert(read.Id == sId);
		Test.Assert(read.TypeName == "MaterialAsset");
		Test.Assert(read.Name == "Wood");

		// The reason is the run's even where the first's type is one the target takes.
		let why = scope String("an older reason");
		String[1] materials = .("MaterialAsset");
		Test.Assert(!AssetDrag.Takes(payload, materials, read, why));
		Test.Assert(why == "This takes one asset");
	}

	/// A run of one is labelled by its name, a run of more by how many.
	[Test]
	public static void ARunIsLabelledByItsOneNameOrByHowMany()
	{
		let payload = scope DragPayload();
		AssetDrag[1] one = .(scope .(sId, "MaterialAsset", "Wood"));
		AssetDrag.Payload(one, payload);
		Test.Assert(payload.Label == "Wood");
		let read = scope AssetDrag();
		let why = scope String();
		Test.Assert(AssetDrag.Takes(payload, Span<String>(), read, why), "a run of one is one asset");

		AssetDrag[3] three = .(scope .(sId, "MaterialAsset", "Wood"), scope .(sOther, "TextureAsset", "Brick"),
			scope .(sThird, "MeshAsset", "Crate"));
		AssetDrag.Payload(three, payload);
		Test.Assert(payload.Label == "3 assets");
	}

	/// ReadAll's list owns what it holds: what it held before goes, read or not.
	[Test]
	public static void ReadAllReplacesWhatTheListHeld()
	{
		let all = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(all); }
		all.Add(new AssetDrag(sThird, "MeshAsset", "Old"));
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "MaterialAsset", "Wood", payload);
		Test.Assert(AssetDrag.ReadAll(payload, all));
		Test.Assert(all.Count == 1);
		Test.Assert(all[0].Id == sId);

		payload.Type.Set("text");
		Test.Assert(!AssetDrag.ReadAll(payload, all));
		Test.Assert(all.IsEmpty);
	}

	/// A run not as Payload writes it is no asset, whole: its count missing, none, too many digits,
	/// more or fewer than its blocks, a block wrong after a good one, or a name's length that does not
	/// end where the name does. A list read into is left empty, and Read leaves its asset as it was.
	[Test]
	public static void ARunNotAsPayloadWritesItIsNotRead()
	{
		let good = scope String("2\n");
		AppendBlock(good, sId, "MaterialAsset", "Wood");
		AppendBlock(good, sOther, "TextureAsset", "Brick");
		let payload = scope DragPayload();
		SetText(payload, good);
		let all = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(all); }
		Test.Assert(AssetDrag.ReadAll(payload, all), "the run as Payload writes it reads");
		Test.Assert(all.Count == 2);

		let read = scope AssetDrag(sThird, "MeshAsset", "Kept");
		let text = scope String();
		void Refused(String why)
		{
			SetText(payload, text);
			Test.Assert(!AssetDrag.ReadAll(payload, all), why);
			Test.Assert(all.IsEmpty, why);
			Test.Assert(!AssetDrag.Read(payload, read), why);
		}

		// The count: missing, none, not a number, too many digits.
		text.Set(good.Substring(2));
		Refused("no count");
		text..Clear()..Append("0\n");
		Refused("a count of none");
		text..Clear()..Append("x\n")..Append(good.Substring(2));
		Refused("a count that is no number");
		text..Clear()..Append("0000000002\n")..Append(good.Substring(2));
		Refused("a count of too many digits");

		// More blocks than the count, or fewer.
		text.Set(good);
		text[0] = '1';
		Refused("a block past the count");
		text.Set(good);
		text[0] = '3';
		Refused("a count past the blocks");

		// The second block wrong, the first good: its guid, its type's end, its name's length.
		text.Set("2\n");
		AppendBlock(text, sId, "MaterialAsset", "Wood");
		text.Append("zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz\nTextureAsset\n5\nBrick\n");
		Refused("a second block with no guid");
		text.Set("2\n");
		AppendBlock(text, sId, "MaterialAsset", "Wood");
		sOther.ToString(text);
		text.Append("\nTextureAsset");
		Refused("a second block with no type's end");
		text.Set("2\n");
		AppendBlock(text, sId, "MaterialAsset", "Wood");
		sOther.ToString(text);
		text.Append("\nTextureAsset\n\nBrick\n");
		Refused("a second block with no name's length");

		// A name's length that does not end where the name does: short, long, or past the text.
		text.Set("1\n");
		sId.ToString(text);
		text.Append("\nMaterialAsset\n3\nWood\n");
		Refused("a name's length short of it");
		// Short by one with the text ending at the name: only the break after the name tells.
		text.Set("1\n");
		sId.ToString(text);
		text.Append("\nMaterialAsset\n3\nWood");
		Refused("a name's length short of it, no break after it");
		text.Set("1\n");
		sId.ToString(text);
		text.Append("\nMaterialAsset\n5\nWood\n");
		Refused("a name's length past it");
		text.Set("1\n");
		sId.ToString(text);
		text.Append("\nMaterialAsset\n50\nWood\n");
		Refused("a name's length past the text");
		text.Set("1\n");
		sId.ToString(text);
		text.Append("\nMaterialAsset\n4\nWood");
		Refused("a name with no line break after it");

		Test.Assert(read.Id == sThird);
		Test.Assert(read.TypeName == "MeshAsset");
		Test.Assert(read.Name == "Kept");
	}
}
