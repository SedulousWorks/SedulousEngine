using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;

namespace Sedulous.Editor.Scene.Tests;

/// The per material preview choice and the shapes it indexes.
class MaterialPreviewPrefsTests
{
	[Test]
	public static void ThePreviewChoiceRoundTripsThroughTheSettingsStore()
	{
		SceneEditorSerializables.RegisterAll();
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
