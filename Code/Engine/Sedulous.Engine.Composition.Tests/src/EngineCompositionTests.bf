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
		// Fourteen domains: thirteen with scene content, and input with none.
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

		// Twenty one resource modules (the render profiles the last), each id once.
		let resources = scope List<ResourceModule>();
		EngineComposition.ResourceModules(resources);
		Test.Assert(resources.Count == 21, scope $"{resources.Count} resource modules");
		for (int i < resources.Count)
		{
			for (int j = i + 1; j < resources.Count; j++)
				Test.Assert(resources[i].Id != resources[j].Id, scope $"{resources[i].Id} twice");
		}

		// Twenty nine factory descriptions, each naming its product and cooked form; after
		// the resource facet runs, every cooked form is a registered serializable.
		let descriptions = scope List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		Test.Assert(descriptions.Count == 29, scope $"{descriptions.Count} descriptions");
		EngineComposition.RegisterResourceTypes();
		for (let desc in descriptions)
		{
			Test.Assert((desc.Product != null) && (desc.Cooked != null) && (desc.Create != null));
			let name = desc.Cooked.GetFullName(.. scope .());
			Test.Assert(GlobalSerializableRegistry.IsRegistered(TypeIdOf(name)), scope $"{name} is not registered");
		}
	}

	[Test]
	public static void AHeadlessHostCreatesEveryFactoryButTheTwoThatNeedAService()
	{
		let set = scope ResourceFactorySet();
		let none = scope NoResourceServices();
		EngineComposition.CreateFactories(set, none);
		Test.Assert(set.Count == 27, scope $"{set.Count} factories");
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
		Test.Assert((set.Count == 27) && (set.Skipped.Length == 2));
	}
}
