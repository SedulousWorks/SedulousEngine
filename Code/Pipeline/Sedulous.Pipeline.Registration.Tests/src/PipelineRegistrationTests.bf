using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Script.Pipeline;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

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
}
