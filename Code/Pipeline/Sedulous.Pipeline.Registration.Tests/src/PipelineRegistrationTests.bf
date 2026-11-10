using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Core.IO;

namespace Sedulous.Pipeline.Registration.Tests;

/// The composition root is complete and consistent: the tripwire counts, the whole type
/// set registering on a real process, every builder's product a registered serializable,
/// and an old project's script class an asset type none of it knows.
static class PipelineRegistrationTests
{
	/// The type an old project's script assets name.
	private const String cOldScriptAsset = "Sedulous.Script.Pipeline.ScriptClassAsset";

	[Test]
	public static void RegisterAllBuildersPopulatesExactlyTheBuilderCount()
	{
		let registry = scope BuilderRegistry();
		Test.Assert(registry.Count == 0);
		PipelineRegistration.RegisterAllBuilders(registry, FindDataRoot(.. scope .()));
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
		Test.Assert(registry.FindFor("as") == null, "a script file is no asset: nothing imports it");
	}

	[Test]
	public static void RegisterPipelineTypesRunsTheWholeSetAndKnowsNoScriptClass()
	{
		// Smoke: every registrar the headless cook needs fires on a real process, none
		// faults, and calling it again is harmless.
		PipelineRegistration.RegisterPipelineTypes();
		PipelineRegistration.RegisterPipelineTypes();

		// An old project's script asset names a type nothing registers, so it reads as unknown
		// (kept, never cooked), and no builder claims it.
		Test.Assert(!GlobalSerializableRegistry.IsRegistered(TypeIdOf(cOldScriptAsset)), "the script class is no longer an asset type");

		// Routing still works after registration.
		let registry = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(registry, FindDataRoot(.. scope .()));
		Test.Assert(registry.Count == PipelineRegistration.cBuilderCount);
		Test.Assert(registry.FindByTypeName(cOldScriptAsset) == null);
	}

	[Test]
	public static void EveryBuildersProductTypeIsARegisteredSerializable()
	{
		// The cook driver stamps the builder's product type into the envelope and the
		// factory reconstructs it by type name, so the product MUST be a registered
		// serializable: the cooked, serialized form, not a runtime type. Audits every
		// builder, the next one included.
		PipelineRegistration.RegisterPipelineTypes();
		let registry = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(registry, FindDataRoot(.. scope .()));
		registry.ForEach(scope (builder) =>
			{
				let product = builder.ProductType;
				Test.Assert(product != null, scope $"{builder.AssetType} names no product");
				let name = product.GetFullName(.. scope .());
				Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{builder.AssetType}: product {name} is not a registered serializable");
			});
	}

	/// Every builder's asset type is a registered serializable too: a source asset is read back by
	/// its type name, so one whose pipeline's registry was never run writes (its creator works) and
	/// then never reads (the vegetation mask was such, its registry run only by the parked editor
	/// page).
	[Test]
	public static void EveryBuildersAssetTypeIsARegisteredSerializable()
	{
		PipelineRegistration.RegisterPipelineTypes();
		let registry = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(registry, FindDataRoot(.. scope .()));
		registry.ForEach(scope (builder) =>
			{
				let name = builder.AssetType.GetFullName(.. scope .());
				Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"asset {name} is not a registered serializable");
			});
	}

	/// Every type a project holds declares its display name ([DisplayName]): without one the
	/// editor names its kind with a blank (a page's bar, the picker). What a project holds is what
	/// a builder cooks or a creator makes (the scene and prefab documents derive no Asset). Thirteen
	/// went without; the next one cannot.
	[Test]
	public static void EveryTypeAProjectHoldsDeclaresItsDisplayName()
	{
		PipelineRegistration.RegisterPipelineTypes();
		let registry = scope BuilderRegistry();
		PipelineRegistration.RegisterAllBuilders(registry, FindDataRoot(.. scope .()));
		registry.ForEach(scope (builder) => { AssertNamed(builder.AssetType); });
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllCreators(creators);
		for (let creator in creators)
		{
			Type made = null;
			for (let type in Type.Types)
			{
				if (type.GetFullName(.. scope .()) == creator.TypeName)
				{
					made = type;
					break;
				}
			}
			Test.Assert(made != null, scope $"creator {creator.Label}: no type {creator.TypeName}");
			AssertNamed(made);
		}
	}

	private static void AssertNamed(Type type)
	{
		let named = type.GetCustomAttribute<DisplayNameAttribute>();
		Test.Assert((named case .Ok(let attribute)) && !String.IsNullOrEmpty(attribute.Name),
			scope $"type {type.GetFullName(.. scope .())} declares no display name");
	}

	/// Every creator the engine ships registers, and each makes an instance of its own type in a
	/// plain source database, with no editor: the headless host's creation and the editor's are the
	/// same code.
	[Test]
	public static void EveryCreatorRegistersAndCreatesItsTypeWithNoEditor()
	{
		PipelineRegistration.RegisterPipelineTypes();
		let creators = scope AssetCreatorRegistry();
		PipelineRegistration.RegisterAllCreators(creators);
		Test.Assert(creators.Count == PipelineRegistration.cCreatorCount, scope $"{creators.Count} creators");

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
		Test.Assert(creators.FindByLabel("GUI Document").Create(null, db.RootGroup, "") == null);

		// A type with several creators has no single one; a type with one does.
		Test.Assert(creators.FindByType(typeof(Sedulous.Materials.Pipeline.MaterialAsset).GetFullName(.. scope .())) == null);
		Test.Assert(creators.FindByType(typeof(Sedulous.Input.Pipeline.InputMapAsset).GetFullName(.. scope .())) != null);
	}
}
