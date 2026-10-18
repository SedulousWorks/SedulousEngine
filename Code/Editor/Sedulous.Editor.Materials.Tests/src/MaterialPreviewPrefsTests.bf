using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Materials.Tests;

/// The per material preview choice and the shapes it indexes.
class MaterialPreviewPrefsTests
{
	[Test]
	public static void ThePreviewChoiceRoundTripsThroughTheSettingsStore()
	{
		MaterialsEditorSerializables.Register();
		let matA = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let matB = Guid(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4);
		let mesh = Guid(5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6);

		let store = scope Settings();
		// Nothing saved: false, the outs untouched.
		uint32 shape = 7;
		Guid meshOut = .();
		Test.Assert(!MaterialPreviewPrefs.Load(store, matA, ref shape, ref meshOut));
		Test.Assert(shape == 7);

		Test.Assert(MaterialPreviewPrefs.Save(store, matA, 3, .()));
		Test.Assert(MaterialPreviewPrefs.Save(store, matB, 0, mesh));
		Test.Assert(!MaterialPreviewPrefs.Save(store, Guid(), 1, .()));
		Test.Assert(!MaterialPreviewPrefs.Save(null, matA, 1, .()));

		Test.Assert(MaterialPreviewPrefs.Load(store, matA, ref shape, ref meshOut));
		Test.Assert((shape == 3) && meshOut.IsNil);
		Test.Assert(MaterialPreviewPrefs.Load(store, matB, ref shape, ref meshOut));
		Test.Assert((shape == 0) && (meshOut == mesh));

		// A second save updates in place.
		Test.Assert(MaterialPreviewPrefs.Save(store, matA, 4, mesh));
		Test.Assert(store.Section<MaterialPreviewSettings>().Prefs.Count == 2);

		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);
		buffer.Seek(0, .Begin);
		let loaded = scope Settings();
		Test.Assert(loaded.Load(buffer, factory) case .Ok);
		Test.Assert(MaterialPreviewPrefs.Load(loaded, matA, ref shape, ref meshOut));
		Test.Assert((shape == 4) && (meshOut == mesh));
	}

	/// The preview preferences moved from Editor.Scene with the page: a file saved before the
	/// move, every name and type id the old one, still loads.
	[Test]
	public static void APreviewChoiceSavedBeforeThePagesMoveStillLoads()
	{
		MaterialsEditorSerializables.Register();
		let material = Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2);
		let store = scope Settings();
		Test.Assert(MaterialPreviewPrefs.Save(store, material, 3, .()));
		let factory = XmlSerializerFactory();
		defer delete factory;
		let buffer = scope MemoryStream();
		Test.Assert(store.Save(buffer, factory) case .Ok);

		// The file as the build before the move wrote it.
		let text = scope String((char8*)buffer.Bytes.Ptr, buffer.Bytes.Length);
		for (let name in StringView[?]("MaterialPreviewSettings", "MaterialPreviewPref"))
		{
			let current = scope $"Sedulous.Editor.Materials.{name}";
			let former = scope $"Sedulous.Editor.Scene.{name}";
			let currentId = scope $"{Sedulous.Core.Serialization.TypeIdOf(current)}";
			Test.Assert(text.Contains(currentId), scope $"{name}'s id is written as {currentId}: {text}");
			text.Replace(currentId, scope $"{Sedulous.Core.Serialization.TypeIdOf(former)}");
			text.Replace(current, former);
		}
		let old = scope MemoryStream();
		old.Write(.((uint8*)text.Ptr, text.Length));
		old.Seek(0, .Begin);

		let loaded = scope Settings();
		Test.Assert(loaded.Load(old, factory) case .Ok);
		Test.Assert(loaded.UnknownSectionCount == 0);
		uint32 shape = 0;
		Guid mesh = .();
		Test.Assert(MaterialPreviewPrefs.Load(loaded, material, ref shape, ref mesh));
		Test.Assert(shape == 3);
	}

	[Test]
	public static void EveryPreviewShapeBuildsAMeshAndOutOfRangeIsTheSphere()
	{
		for (uint32 i < (uint32)MaterialPreviewShapes.Names.Count)
		{
			let mesh = MaterialPreviewShapes.Build(i);
			defer delete mesh;
			Test.Assert(mesh.VertexCount > 0);
		}
		let sphere = MaterialPreviewShapes.Build(0);
		defer delete sphere;
		let fallback = MaterialPreviewShapes.Build(99);
		defer delete fallback;
		Test.Assert(fallback.VertexCount == sphere.VertexCount);
	}
}
