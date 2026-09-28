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

		// Twenty resource modules, each id once.
		let resources = scope List<ResourceModule>();
		EngineComposition.ResourceModules(resources);
		Test.Assert(resources.Count == 20, scope $"{resources.Count} resource modules");
		for (int i < resources.Count)
		{
			for (int j = i + 1; j < resources.Count; j++)
				Test.Assert(resources[i].Id != resources[j].Id, scope $"{resources[i].Id} twice");
		}

		// Twenty seven factory descriptions, each naming its product and cooked form; after
		// the resource facet runs, every cooked form is a registered serializable.
		let descriptions = scope List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		Test.Assert(descriptions.Count == 27, scope $"{descriptions.Count} descriptions");
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
		Test.Assert(set.Count == 25, scope $"{set.Count} factories");
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
		// A second call adds nothing.
		EngineComposition.CreateFactories(set, none);
		Test.Assert((set.Count == 25) && (set.Skipped.Length == 2));
	}
}
