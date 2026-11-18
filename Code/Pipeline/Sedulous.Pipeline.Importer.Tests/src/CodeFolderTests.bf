using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;

namespace Sedulous.Pipeline.Importer.Tests;

/// Where an import's copies land: in its folder under the sources (an asset group's), and a name
/// starting Code/ in the project's code folder, beside Sources/.
class CodeFolderTests
{
	private static void Write(StringView folder, StringView name, StringView text, String outPath)
	{
		PathJoin(folder, name, outPath);
		Test.Assert(WriteFile(outPath, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}

	/// A copy into Code, which the context's code folder holds: the name carries the folder
	/// (Code/Hero.as), the file lands in the code folder, a second file of that name goes beside
	/// it (Code/Hero.2.as), the ledger keys the names with their folder, a deeper folder is made
	/// when missing, and a copy with no folder still lands at the sources' root.
	[Test]
	public static void ACopyIntoCodeLandsInTheProjectsCodeFolder()
	{
		const String root = "scratch_importer_code";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), root, .. scope .());
		let sources = PathJoin(dir, "Sources", .. scope .());
		let code = PathJoin(dir, "Code", .. scope .());
		let one = PathJoin(dir, "one", .. scope .());
		let two = PathJoin(dir, "two", .. scope .());
		for (let folder in scope StringView[](sources, code, one, two))
			Test.Assert(CreateDirectory(folder));
		let context = scope ImportContext(sources);
		context.CodeRoot.Set(code);
		ImportPaths.ImportLedgerPath(PathJoin(dir, ".cache", .. scope .()), context.LedgerPath);
		context.Folder.Set("Code");

		let first = Write(one, "Hero.as", "first", .. scope .());
		let a = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, first, a, false) case .Ok);
		Test.Assert(a == "Code/Hero.as", a);
		Test.Assert(FileExists(PathJoin(code, "Hero.as", .. scope .())));
		Test.Assert(!FileExists(PathJoin(sources, "Hero.as", .. scope .())));
		Test.Assert(context.FileOf("Code/Hero.as", .. scope .()) == PathJoin(code, "Hero.as", .. scope .()));
		Test.Assert(ImportPaths.ImportOriginOf(context.LedgerPath, "Code/Hero.as", .. scope .()) == first);

		let second = Write(two, "Hero.as", "second", .. scope .());
		let b = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(context, second, b, true) case .Ok);
		Test.Assert(b == "Code/Hero.2.as", b);
		Test.Assert(FileExists(PathJoin(code, "Hero.2.as", .. scope .())));

		// In a group's folder: the name carries it, the file lands under it (made when missing).
		let inGroup = scope ImportContext(sources);
		inGroup.CopyFrom(context);
		inGroup.Folder.Set("Code/Heroes/Melee");
		let grouped = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(inGroup, first, grouped, true) case .Ok);
		Test.Assert(grouped == "Code/Heroes/Melee/Hero.as", grouped);
		Test.Assert(FileExists(PathJoin(code, "Heroes/Melee/Hero.as", .. scope .())));
		Test.Assert(context.Folder == "Code", "a copy leaves the context it was made from as it was");
		let artGroup = scope ImportContext(sources);
		artGroup.Folder.Set("Textures/UI");
		Test.Assert(artGroup.InFolder("x.png", .. scope .()) == "Textures/UI/x.png");

		// A copy with no folder still lands in Sources.
		let plain = scope ImportContext(sources);
		plain.CopyFrom(context);
		plain.Folder.Clear();
		let c = scope String();
		Test.Assert(ImportPaths.CopyIntoSources(plain, second, c, true) case .Ok);
		Test.Assert(c == "Hero.as", c);
		Test.Assert(FileExists(PathJoin(sources, "Hero.as", .. scope .())));
	}

	/// A single asset's copy goes in its group's folder, under Code/ when the importer says code;
	/// the same file imported again into its group is its own earlier import (its file name, in
	/// the group's folder) and overwrites its copy in place.
	[Test]
	public static void AClaimedAssetsCopyGoesInItsGroupsFolder()
	{
		ImporterTestTypes.RegisterAll();
		const String root = "scratch_importer_group_folder";
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let dir = PathJoin(GetCurrentDirectory(.. scope .()), root, .. scope .());
		let sources = PathJoin(dir, "Sources", .. scope .());
		let code = PathJoin(dir, "Code", .. scope .());
		let content = PathJoin(dir, "Content", .. scope .());
		let outside = PathJoin(dir, "outside", .. scope .());
		for (let folder in scope StringView[](sources, code, content, outside))
			Test.Assert(CreateDirectory(folder));
		let mount = scope NativeFileSystem(content);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let database = scope ContentDatabase(mount, factory, "asset");
		let ui = database.RootGroup.CreateGroup("Textures").CreateGroup("UI");
		let typeName = "Sedulous.Pipeline.Importer.Tests.SourcedAsset";
		let context = scope ImportContext(sources);
		context.CodeRoot.Set(code);
		ImportPaths.ImportLedgerPath(PathJoin(dir, ".cache", .. scope .()), context.LedgerPath);

		let png = Write(outside, "icon.png", "png", .. scope .());
		let fileName = scope String();
		let claimed = ImportPaths.ClaimSingleAsset(context, ui, null, png, typeName, fileName);
		Test.Assert(claimed case .Ok);
		let instance = claimed.Value;
		Test.Assert(fileName == "Textures/UI/icon.png", fileName);
		Test.Assert(FileExists(PathJoin(sources, "Textures/UI/icon.png", .. scope .())));
		Test.Assert(context.Folder.IsEmpty, "the caller's context is not narrowed");
		let asset = scope SourcedAsset();
		asset.FileName.Set(fileName);
		Test.Assert(instance.WriteObject(asset) case .Ok);

		// The same file again, changed: its own copy in the group's folder takes the bytes.
		Write(outside, "icon.png", "png, edited", scope .());
		let again = scope String();
		let clash = scope ImportClash();
		let reclaimed = ImportPaths.ClaimSingleAsset(context, ui, null, png, typeName, again, clash);
		Test.Assert(reclaimed case .Ok);
		Test.Assert(reclaimed.Value === instance);
		Test.Assert(clash.Kind == .Reimport);
		Test.Assert(again == "Textures/UI/icon.png", again);
		Test.Assert(!FileExists(PathJoin(sources, "Textures/UI/icon.2.png", .. scope .())));

		// Code: under Code/, in the group's folder there; at the root group, Code/ itself.
		let script = Write(outside, "Hero.as", "class Hero {}", .. scope .());
		let scriptName = scope String();
		Test.Assert(ImportPaths.ClaimSingleAsset(context, ui, null, script, typeName, scriptName, null, SourcePath.CodeFolder) case .Ok);
		Test.Assert(scriptName == "Code/Textures/UI/Hero.as", scriptName);
		Test.Assert(FileExists(PathJoin(code, "Textures/UI/Hero.as", .. scope .())));
		let tool = Write(outside, "Tool.as", "class Tool {}", .. scope .());
		let toolName = scope String();
		Test.Assert(ImportPaths.ClaimSingleAsset(context, database.RootGroup, null, tool, typeName, toolName, null, SourcePath.CodeFolder) case .Ok);
		Test.Assert(toolName == "Code/Tool.as", toolName);
		Test.Assert(FileExists(PathJoin(code, "Tool.as", .. scope .())));
	}

	/// Before the ledger knew a file, its own earlier import was told by the file name; in a
	/// group's folder it is the name after the folder that decides.
	[Test]
	public static void AnEarlierImportInAGroupsFolderIsToldByItsFileName()
	{
		ImporterTestTypes.RegisterAll();
		const String root = "scratch_importer_clash_folder";
		RemoveDirectoryRecursive(root);
		Test.Assert(CreateDirectory(root));
		defer RemoveDirectoryRecursive(root);
		let mount = scope NativeFileSystem(root);
		let factory = XmlSerializerFactory();
		defer delete factory;
		let database = scope ContentDatabase(mount, factory, "asset");
		let textures = database.RootGroup.CreateGroup("Textures");
		let typeName = "Sedulous.Pipeline.Importer.Tests.SourcedAsset";
		let asset = scope SourcedAsset();
		asset.FileName.Set("Textures/stone.png");
		Test.Assert(textures.CreateInstance("stone", typeName).WriteObject(asset) case .Ok);

		let clash = scope ImportClash();
		ImportPaths.FindImportClash(textures, "stone", typeName, "/elsewhere/stone.png", "", clash);
		Test.Assert(clash.Kind == .Reimport);
		ImportPaths.FindImportClash(textures, "stone", typeName, "/elsewhere/other.png", "", clash);
		Test.Assert(clash.Kind == .SameType);

		// And its stored selection is found by that name too.
		let plan = scope ImportPlan();
		ImportPaths.SingleAssetStoredSelection(textures, "/elsewhere/stone.png", typeName, plan);
		Test.Assert(plan.Entries.Count == 1);
	}
}
