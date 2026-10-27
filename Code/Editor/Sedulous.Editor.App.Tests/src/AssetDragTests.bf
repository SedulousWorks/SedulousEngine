using System;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// What an asset carries when dragged: the payload it makes, read back whole; a target that takes
/// some types taking it or naming why not; anything else not an asset. Then what Sedulous adds so
/// each behaviour has a test: the effects a drag allows, a payload filled over an older one, a name
/// with a line break, a payload of the asset's type with a value that is no asset, a target that
/// names a type in full or short while an instance names it in full, and a reason that replaces
/// what the string held.
class AssetDragTests
{
	private static readonly Guid sId = Guid(0xabcd, 0x1234, 0x5678, 1, 2, 3, 4, 5, 6, 7, 8);

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

	/// An asset is linked or copied where it is dropped, never moved out of the browser.
	[Test]
	public static void PayloadAllowsLinkAndCopy()
	{
		let payload = scope DragPayload();
		AssetDrag.Payload(sId, "MaterialAsset", "Wood", payload);
		Test.Assert(payload.Allowed == (DropEffectsLink | DropEffectsCopy));
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
		// for one, and a guid with no type.
		let wrong = scope DragPayload();
		wrong.Type.Set(AssetDrag.cType);
		wrong.Value = System.Variant.Create((uint64)7);
		Test.Assert(!AssetDrag.Read(wrong, read));
		wrong.Value.Dispose();
		wrong.Value = TextVariant("zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz\nTextureAsset\nGrass"); // a guid's length, not a guid
		Test.Assert(!AssetDrag.Read(wrong, read));
		wrong.Value.Dispose();
		wrong.Value = TextVariant("short\nTextureAsset\nGrass");
		Test.Assert(!AssetDrag.Read(wrong, read));
		wrong.Value.Dispose();
		let noType = scope String();
		Guid.Create().ToString(noType);
		noType.Append("\nTextureAsset");
		wrong.Value = TextVariant(noType);
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
}
