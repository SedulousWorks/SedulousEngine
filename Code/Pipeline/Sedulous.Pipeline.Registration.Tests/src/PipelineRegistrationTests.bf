using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Script.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Core.IO;

namespace Sedulous.Pipeline.Registration.Tests;

/// The composition root is complete and consistent: the tripwire counts, the whole type
/// set registering on a real process, every builder's product a registered serializable,
/// and the script cook standing behind the surface.
static class PipelineRegistrationTests
{
	[Test]
	public static void RegisterAllBuildersPopulatesExactlyTheBuilderCount()
	{
		let registry = scope BuilderRegistry();
		Test.Assert(registry.Count == 0);
		PipelineRegistration.RegisterAllBuilders(registry);
		Test.Assert(registry.Count == PipelineRegistration.cBuilderCount, scope $"{registry.Count} builders");

		// Each handles its own asset type: no two builders claim one.
		let seen = scope List<Type>();
		registry.ForEach(scope [&] (builder) =>
			{
				Test.Assert(!seen.Contains(builder.AssetType), scope $"{builder.AssetType} shares an asset type");
				seen.Add(builder.AssetType);
			});
	}

	[Test]
	public static void RegisterAllImportersPopulatesExactlyTheImporterCount()
	{
		let registry = scope ImporterRegistry();
		Test.Assert(registry.Count == 0);
		PipelineRegistration.RegisterAllImporters(registry);
		Test.Assert(registry.Count == PipelineRegistration.cImporterCount, scope $"{registry.Count} importers");
	}

	[Test]
	public static void RegisterPipelineTypesRunsTheWholeSetAndStandsUpTheScriptCook()
	{
		// Smoke: every registrar the headless cook needs fires on a real process, none
		// faults, and calling it again is harmless.
		PipelineRegistration.RegisterPipelineTypes();
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();

		Test.Assert(PipelineRegistration.Surface != null);
		Test.Assert(PipelineRegistration.Surface.Types.Count == Sedulous.Pipeline.ScriptSurface.PipelineScriptSurface.TypeCount, "the pipeline surface is populated, whole");
		Test.Assert(ScriptLanguageCooks.Find("angelscript") != null, "the AngelScript cook is registered behind the surface");
		Test.Assert(ScriptLanguageCooks.LanguageOf("as", .. scope .()) == "angelscript");

		// Routing still works after registration.
		let registry = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(registry);
		Test.Assert(registry.Count == PipelineRegistration.cBuilderCount);
	}

	[Test]
	public static void EveryBuildersProductTypeIsARegisteredSerializable()
	{
		// The cook driver stamps the builder's product type into the envelope and the
		// factory reconstructs it by type name, so the product MUST be a registered
		// serializable: the cooked, serialized form, not a runtime type. Audits every
		// builder, the next one included.
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let registry = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(registry);
		registry.ForEach(scope (builder) =>
			{
				let product = builder.ProductType;
				Test.Assert(product != null, scope $"{builder.AssetType} names no product");
				let name = product.GetFullName(.. scope .());
				Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{builder.AssetType}: product {name} is not a registered serializable");
			});
	}

	/// Every creator the engine ships registers, three per script language on top of the
	/// fixed set, and each makes an instance of its own type in a plain source database, with
	/// no editor: the headless host's creation and the editor's are the same code.
	[Test]
	public static void EveryCreatorRegistersAndCreatesItsTypeWithNoEditor()
	{
		PipelineRegistration.RegisterPipelineTypes();
		defer PipelineRegistration.Teardown();
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllCreators(creators);
		let languages = scope List<String>();
		defer { ClearAndDeleteItems!(languages); }
		ScriptLanguageCooks.CollectLanguages(languages);
		Test.Assert(creators.Count == PipelineRegistration.cCreatorCount + ScriptCreators.CountFor(languages.Count),
			scope $"{creators.Count} creators");

		let root = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_registration_creators", .. scope .());
		RemoveDirectoryRecursive(root);
		defer RemoveDirectoryRecursive(root);
		let content = PathJoin(root, "Content", .. scope .());
		let sources = PathJoin(root, "Sources", .. scope .());
		CreateDirectory(root);
		CreateDirectory(content);
		CreateDirectory(sources);
		let contentFs = scope NativeFileSystem(content);
		SerializerFactory factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
		defer delete factory;
		let db = scope ContentDatabase(contentFs, factory, "xasset");

		for (let creator in creators)
		{
			let instance = creator.Create(null, db.RootGroup, sources);
			Test.Assert(instance != null, scope $"'{creator.Label}' created nothing");
			Test.Assert(instance.TypeName == creator.TypeName, scope $"'{creator.Label}' made a {instance.TypeName}");
		}

		// A picked group wins over a creator's default folder.
		let picked = db.RootGroup.CreateGroup("Picked");
		let material = creators.FindByLabel("PBR Material").Create(picked, db.RootGroup, sources);
		Test.Assert((material != null) && (material.OwningGroup == picked));

		// A file backed creator refuses without a sources folder rather than write nowhere.
		Test.Assert(creators.FindByLabel("UI Document").Create(null, db.RootGroup, "") == null);

		// A type with several creators has no single one; a type with one does.
		Test.Assert(creators.FindByType(typeof(Sedulous.Materials.Pipeline.MaterialAsset).GetFullName(.. scope .())) == null);
		Test.Assert(creators.FindByType(typeof(Sedulous.Input.Pipeline.InputMapAsset).GetFullName(.. scope .())) != null);
	}
}
