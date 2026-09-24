using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter.Tests;

/// The files a text model points at travel with it.
///
/// Importing only the document leaves a source set that cannot be read again: its buffers and
/// its images live in sibling files, so every relative reference is copied, keeping the
/// relative path the copied document still spells.
class GltfSidecarTests
{
	/// A document naming a buffer beside it and an image in a SUBFOLDER, which is the shape
	/// that once failed: the nested copy had no parent directory to land in.
	private const String cDocument = """
{"asset":{"version":"2.0"},"buffers":[{"uri":"character.bin"}],"images":[{"uri":"textures/Texture.png"},{"uri":"data:application/octet-stream;base64,AAA"},{"uri":"../escapes/out.png"}]}
""";

	private static void WriteSource(ImportFixture fixture, String outDropped)
	{
		fixture.WriteDroppedFile("character.gltf", cDocument, outDropped);
		fixture.WriteBeside("character.bin", "buffer bytes");
		fixture.WriteBeside("textures/Texture.png", "image bytes");
	}

	private static void CheckSourcesTree(ImportFixture fixture)
	{
		for (let relative in scope String[]("Sources/character.gltf", "Sources/character.bin",
			"Sources/textures/Texture.png"))
		{
			let path = scope String();
			fixture.SubPath(relative, path);
			Test.Assert(FileExists(path), relative);
		}

		// A data reference is already inside the copied document, and one climbing out of the
		// model's own directory would land outside the sources tree.
		let escaped = scope String();
		fixture.SubPath("Sources/escapes/out.png", escaped);
		Test.Assert(!FileExists(escaped));
	}

	[Test]
	public static void TheReferencedFilesLandInSourcesOnTheInlinePath()
	{
		let fixture = scope ImportFixture("scratch_gltf_sidecars_inline");
		let dropped = scope String();
		WriteSource(fixture, dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		CheckSourcesTree(fixture);
	}

	/// The worker path: the import QUEUES its bulk writes and the caller runs them while the
	/// prepared model stays alive, because the parked pixel writes BORROW its decoded images.
	[Test]
	public static void TheDeferredWritesLandTheSameFilesWhenTheyRun()
	{
		let fixture = scope ImportFixture("scratch_gltf_sidecars_deferred");
		let dropped = scope String();
		WriteSource(fixture, dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let writes = scope List<DeferredImportWrite>();
		defer { ClearAndDeleteItems!(writes); }

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, writes);
		Test.Assert(imported case .Ok);
		Test.Assert(!writes.IsEmpty);

		// EVERY write has to succeed: a failed one skipped the steps after the import, so the
		// prefab and scene generators never ran.
		for (let write in writes)
			Test.Assert(write.Execute() case .Ok, scope String(write.Label));

		CheckSourcesTree(fixture);

		// The deferred envelopes wrote too: the mesh assets are readable, geometry sidecar
		// and all.
		let group = imported.Value.OwningGroup;
		let prop = group.GetInstance("Prop");
		Test.Assert(prop != null);
		let object = prop.ReadObject();
		Test.Assert(object != null);
		delete Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object));
	}

	/// The lazy geometry path must produce exactly what the eager one does.
	///
	/// A prepared model outlives the flush, so its mesh conversion, level chain and
	/// serialization ride the deferred write and run on the worker; an inline model has that
	/// work done during the import call. Same model, same bytes, or the deferral changed the
	/// asset rather than only when it was built.
	[Test]
	public static void TheLazyGeometryMatchesTheEagerGeometryByteForByte()
	{
		/// Imports once and returns the Prop mesh's geometry stream.
		static void ImportAndRead(StringView scratch, bool deferred, List<uint8> outBytes)
		{
			let fixture = scope ImportFixture(scratch);
			let dropped = scope String();
			WriteSource(fixture, dropped);

			// The SAME prepared model both ways, so the only variable is when its geometry is
			// built: deferring parks the work, and no writes list does it during the call.
			let payload = scope LoadedModel();
			ModelFixture.Character(payload.Model);

			let writes = scope List<DeferredImportWrite>();
			defer { ClearAndDeleteItems!(writes); }

			let importer = scope ModelFileImporter();
			let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
				payload, deferred ? writes : null);
			Test.Assert(imported case .Ok);
			for (let write in writes)
				Test.Assert(write.Execute() case .Ok, scope String(write.Label));

			let group = imported.Value.OwningGroup;
			let prop = group.GetInstance("Prop");
			Test.Assert(prop != null);
			let stream = prop.ReadData(Sedulous.Geometry.Pipeline.MeshAssetStorage.cGeometryStreamName);
			Test.Assert(stream != null);
			defer delete stream;
			let size = (int)stream.Size();
			outBytes.Resize(size);
			if (size > 0)
				Test.Assert(stream.Read(.(outBytes.Ptr, size)) == size);
		}

		let eager = scope List<uint8>();
		let lazy = scope List<uint8>();
		ImportAndRead("scratch_geometry_eager", false, eager);
		ImportAndRead("scratch_geometry_lazy", true, lazy);

		Test.Assert(!eager.IsEmpty, "the eager import wrote geometry");
		Test.Assert(eager.Count == lazy.Count,
			scope $"same size: eager {eager.Count}, lazy {lazy.Count}");
		Test.Assert(Internal.MemCmp(eager.Ptr, lazy.Ptr, eager.Count) == 0,
			"deferring WHEN the geometry is built must not change WHAT is built");
	}
}
