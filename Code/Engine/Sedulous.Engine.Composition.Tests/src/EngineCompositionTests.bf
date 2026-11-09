using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Domain;
using Sedulous.Resource;

namespace Sedulous.Engine.Composition.Tests;

/// The composition root's tripwires: one list of domains answering every facet. A domain,
/// a resource module or a factory added or lost changes a count here DELIBERATELY.
static class EngineCompositionTests
{
	[Test]
	public static void OneListOfDomainsAnswersTheSceneAndResourceFacets()
	{
		// Fourteen domains: thirteen with scene content (the GUI's the last), and input with none.
		let modules = EngineComposition.Modules;
		Test.Assert(modules.Count == 14, scope $"{modules.Count} domains");
		int withScene = 0;
		for (let domain in modules)
		{
			if (domain.HasScene)
				withScene++;
		}
		Test.Assert(withScene == 13);
		// Each domain id once; input is listed though it has no scene content.
		bool sawInput = false;
		for (int i < modules.Count)
		{
			for (int j = i + 1; j < modules.Count; j++)
				Test.Assert(modules[i].Id != modules[j].Id, scope $"{modules[i].Id} twice");
			if (modules[i].Id == "input")
			{
				sawInput = true;
				Test.Assert(!modules[i].HasScene);
			}
		}
		Test.Assert(sawInput);

		// Twenty two resource modules, each id once: the GUI's documents and sheets among them, and
		// its vector images and fonts.
		let resources = scope List<ResourceModule>();
		EngineComposition.ResourceModules(resources);
		Test.Assert(resources.Count == 22, scope $"{resources.Count} resource modules");
		for (int i < resources.Count)
		{
			for (int j = i + 1; j < resources.Count; j++)
				Test.Assert(resources[i].Id != resources[j].Id, scope $"{resources[i].Id} twice");
		}

		// Thirty one factory descriptions (the scene's prefabs among them, the GUI's documents and
		// sheets the last two), each naming its product and cooked form; after the resource facet
		// runs, every cooked form is a registered serializable.
		let descriptions = scope List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		Test.Assert(descriptions.Count == 31, scope $"{descriptions.Count} descriptions");
		EngineComposition.RegisterResourceTypes();
		for (let desc in descriptions)
		{
			Test.Assert((desc.Product != null) && (desc.Cooked != null) && (desc.Create != null));
			let name = desc.Cooked.GetFullName(.. scope .());
			Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{name} is not registered");
		}
	}

	private static int sPluginTypesRegistered = 0;
	private static void RegisterPluginTypes() => sPluginTypesRegistered++;
	private static void InstallPluginScene(Sedulous.Scene.Scene scene) {}

	/// A plugin's domain joins after the engine's, registers its resource types at once, and
	/// leaves on removal; one with scene content is refused (its managers reach scenes through
	/// SceneModuleContributions instead).
	[Test]
	public static void APluginsDomainJoinsAfterTheEnginesRegistersAtOnceAndLeavesOnRemoval()
	{
		let modules = EngineComposition.Modules.Count;
		let resources = scope List<ResourceModule>();
		EngineComposition.ResourceModules(resources);
		let resourceCount = resources.Count;
		sPluginTypesRegistered = 0;

		let pluginResources = scope ResourceModule("plugin_probe", => RegisterPluginTypes, null);
		let domain = scope DomainModule("plugin_probe", null, new .(pluginResources));
		let token = EngineComposition.AddPluginDomain(domain);
		Test.Assert(token != 0);
		Test.Assert(EngineComposition.Modules.Count == modules + 1);
		Test.Assert(EngineComposition.Modules[modules] === domain, "after the engine's own");
		let joined = scope List<ResourceModule>();
		EngineComposition.ResourceModules(joined);
		Test.Assert(joined.Count == resourceCount + 1);
		Test.Assert(sPluginTypesRegistered == 1, "registered at once");
		EngineComposition.RegisterResourceTypes(); // a later startup registration reaches it too
		Test.Assert(sPluginTypesRegistered == 2);

		// A second one, removed first: each token takes its own out.
		let second = scope DomainModule("plugin_second", null);
		let secondToken = EngineComposition.AddPluginDomain(second);
		Test.Assert((secondToken != 0) && (secondToken != token));
		EngineComposition.RemovePluginDomain(token);
		Test.Assert(EngineComposition.Modules.Count == modules + 1);
		Test.Assert(EngineComposition.Modules[modules] === second);
		EngineComposition.RemovePluginDomain(secondToken);
		EngineComposition.RemovePluginDomain(secondToken); // twice: nothing
		Test.Assert(EngineComposition.Modules.Count == modules);
		let left = scope List<ResourceModule>();
		EngineComposition.ResourceModules(left);
		Test.Assert(left.Count == resourceCount);

		let withScene = scope DomainModule("plugin_scene", => InstallPluginScene);
		Test.Assert(EngineComposition.AddPluginDomain(withScene) == 0);
		Test.Assert(EngineComposition.Modules.Count == modules);
	}

	[Test]
	public static void AHeadlessHostCreatesEveryFactoryButTheTwoThatNeedAService()
	{
		let set = scope ResourceFactorySet();
		let none = scope NoResourceServices();
		EngineComposition.CreateFactories(set, none);
		Test.Assert(set.Count == 29, scope $"{set.Count} factories"); // thirty one described, the two needing a service skipped
		// The two skipped name what they wanted: the graphics device and the shader system.
		Test.Assert(set.Skipped.Length == 2);
		bool device = false;
		bool shaders = false;
		for (let desc in set.Skipped)
		{
			let name = desc.Service.GetFullName(.. scope .());
			device |= (name == "Sedulous.RHI.IDevice");
			shaders |= (name == "Sedulous.Shaders.ShaderSystem");
		}
		Test.Assert(device && shaders);
		// Every created factory agrees with its description: the product it is keyed on and the
		// cooked form it reads.
		let descriptions = scope List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		for (let factory in set.Factories)
		{
			ResourceFactoryDesc* described = null;
			for (let desc in descriptions)
			{
				if (ResourceManager.ProductTypeIdOf(desc.Product) == factory.ProductTypeId)
					described = desc;
			}
			let name = factory.CookedType.GetFullName(.. scope .());
			Test.Assert(described != null, scope $"the factory reading {name} has no description");
			Test.Assert(described.Cooked == factory.CookedType, scope $"{name} is not its description's cooked form");
		}
		// A second call adds nothing.
		EngineComposition.CreateFactories(set, none);
		Test.Assert((set.Count == 29) && (set.Skipped.Length == 2));
	}
}
