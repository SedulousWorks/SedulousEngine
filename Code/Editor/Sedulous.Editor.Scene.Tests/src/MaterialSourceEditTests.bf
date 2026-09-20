using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Materials.Pipeline;

namespace Sedulous.Editor.Scene.Tests;

/// The material page's headless edits: named uniforms, the texture slot table, and the
/// snapshot the undo step carries.
class MaterialSourceEditTests
{
	private static MaterialSource PbrSource()
	{
		let built = MaterialPresets.CreatePbr("M");
		defer delete built;
		let source = new MaterialSource();
		MaterialSource.FromMaterial(built, .(), source);
		return source;
	}

	[Test]
	public static void UniformsReadAndWriteByPropertyName()
	{
		let source = PbrSource();
		defer delete source;

		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Roughness") == 0.5f);
		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Metallic") == 0.0f);
		let white = MaterialSourceEdit.ReadFloat4(source, "BaseColor");
		Test.Assert((white.X == 1.0f) && (white.W == 1.0f));

		Test.Assert(MaterialSourceEdit.WriteFloat(source, "Metallic", 0.75f));
		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Metallic") == 0.75f);
		// The neighbours are untouched.
		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Roughness") == 0.5f);

		Test.Assert(MaterialSourceEdit.WriteFloat4(source, "BaseColor", .(0.2f, 0.4f, 0.6f, 0.8f)));
		let tinted = MaterialSourceEdit.ReadFloat4(source, "BaseColor");
		Test.Assert((tinted.X == 0.2f) && (tinted.Y == 0.4f) && (tinted.Z == 0.6f) && (tinted.W == 0.8f));

		// An unknown name is refused and the fallback comes back.
		Test.Assert(!MaterialSourceEdit.WriteFloat(source, "Nope", 1.0f));
		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Nope", 9.0f) == 9.0f);
	}

	[Test]
	public static void TextureSlotsBindReplaceAndUnbind()
	{
		let source = PbrSource();
		defer delete source;
		let a = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
		let b = Guid(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);

		// The preset binds nothing.
		Test.Assert(source.TextureSlots.Count == 0);
		Test.Assert(MaterialSourceEdit.TextureFor(source, "AlbedoMap").IsNil);

		// Bind adds the slot; a second bind replaces in place.
		MaterialSourceEdit.SetTexture(source, "AlbedoMap", a);
		MaterialSourceEdit.SetTexture(source, "NormalMap", b);
		Test.Assert(source.TextureSlots.Count == 2);
		Test.Assert(MaterialSourceEdit.TextureFor(source, "AlbedoMap") == a);
		MaterialSourceEdit.SetTexture(source, "AlbedoMap", b);
		Test.Assert(source.TextureSlots.Count == 2);
		Test.Assert(MaterialSourceEdit.TextureFor(source, "AlbedoMap") == b);

		// A nil id drops the slot entirely; unbinding an absent slot is a no-op.
		MaterialSourceEdit.SetTexture(source, "AlbedoMap", .());
		Test.Assert(source.TextureSlots.Count == 1);
		Test.Assert(source.TextureIds.Count == 1);
		Test.Assert(MaterialSourceEdit.TextureFor(source, "AlbedoMap").IsNil);
		Test.Assert(MaterialSourceEdit.TextureFor(source, "NormalMap") == b);
		MaterialSourceEdit.SetTexture(source, "EmissiveMap", .());
		Test.Assert(source.TextureSlots.Count == 1);
	}

	[Test]
	public static void SnapshotRestoresEveryEditedField()
	{
		MaterialsPipeline.RegisterAll();
		let source = PbrSource();
		defer delete source;
		let before = scope List<uint8>();
		MaterialSourceEdit.Snapshot(source, before);
		Test.Assert(before.Count > 0);

		// Edit a uniform, a texture, and a pipeline preset.
		MaterialSourceEdit.WriteFloat(source, "Metallic", 1.0f);
		MaterialSourceEdit.SetTexture(source, "AlbedoMap", Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5));
		source.BlendMode = .Additive;
		let after = scope List<uint8>();
		MaterialSourceEdit.Snapshot(source, after);
		Test.Assert(after.Count != before.Count || Internal.MemCmp(after.Ptr, before.Ptr, before.Count) != 0);

		// Undo: the before blob puts everything back.
		MaterialSourceEdit.Apply(source, before);
		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Metallic") == 0.0f);
		Test.Assert(source.TextureSlots.Count == 0);
		Test.Assert(source.BlendMode == .Opaque);

		// Redo: the after blob brings the edits back.
		MaterialSourceEdit.Apply(source, after);
		Test.Assert(MaterialSourceEdit.ReadFloat(source, "Metallic") == 1.0f);
		Test.Assert(source.TextureSlots.Count == 1);
		Test.Assert(source.TextureSlots[0] == "AlbedoMap");
		Test.Assert(source.BlendMode == .Additive);
	}
}
