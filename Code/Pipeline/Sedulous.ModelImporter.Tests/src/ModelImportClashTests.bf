using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter.Tests;

/// A model claims its folder by the import's clash rule (ImportPaths.FindImportClash): the same
/// file again is a re-import in place (its manifest's guid kept); another folder's file of the same
/// name is refused, or kept beside in the next folder ("character.2") with its own copy under the
/// sources tree, the first model's untouched.
class ModelImportClashTests
{
	private static Result<Instance, ErrorCode> ImportPrepared(IFileImporter importer, StringView path, ImportFixture fixture)
	{
		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);
		return importer.Import(path, fixture.Context, fixture.RootGroup, null, prepared, null);
	}

	private static void FileOf(Instance instance, String outFileName)
	{
		let manifest = ImportFixture.ReadManifest(instance);
		defer delete manifest;
		outFileName.Append(manifest.FileName.Value);
	}

	[Test]
	public static void TheSameFileReimportsInPlaceAnotherFileOfItsNameIsRefusedOrKeptBeside()
	{
		let fixture = scope ImportFixture("scratch_model_clash");
		ImportPaths.ImportLedgerPath(fixture.SubPath(".cache", .. scope .()), fixture.Context.LedgerPath);
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "not read: the model arrives prepared", dropped);
		// Another folder's character.glb: another file (a different model) of the same name.
		fixture.WriteBeside("elsewhere/character.glb", "another model");
		let other = fixture.SubPath("elsewhere/character.glb", .. scope .());

		IFileImporter importer = scope ModelFileImporter();
		let root = fixture.RootGroup;
		let first = ImportPrepared(importer, dropped, fixture);
		Test.Assert(first case .Ok);
		let manifest = first.Value.Id;
		let reimport = scope ImportClash();
		importer.FindClash(root, dropped, null, fixture.Context.LedgerPath, reimport);
		Test.Assert(reimport.Kind == .Reimport);
		let again = ImportPrepared(importer, dropped, fixture);
		Test.Assert(again case .Ok);
		Test.Assert(again.Value.Id == manifest);
		Test.Assert(root.GetGroup("character.2") == null);

		let clash = scope ImportClash();
		importer.FindClash(root, other, null, fixture.Context.LedgerPath, clash);
		Test.Assert(clash.Kind == .SameType);
		Test.Assert(ImportPrepared(importer, other, fixture) case .Err);
		fixture.Context.OnConflict = .KeepBoth;
		let beside = ImportPrepared(importer, other, fixture);
		Test.Assert(beside case .Ok);
		Test.Assert(beside.Value.Id != manifest);
		let second = root.GetGroup("character.2");
		Test.Assert(second != null);
		Test.Assert(beside.Value.OwningGroup == second);
		Test.Assert(FileOf(beside.Value, .. scope .()) == "character.2.glb");
		Test.Assert(FileOf(fixture.Db.GetInstance(manifest), .. scope .()) == "character.glb");
	}
}
