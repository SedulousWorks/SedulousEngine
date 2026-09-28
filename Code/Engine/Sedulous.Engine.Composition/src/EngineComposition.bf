using System;
using System.Collections;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Domain;
using Sedulous.Engine.Input;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Net;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Script;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.UI;
using Sedulous.Engine.Vegetation;
using Sedulous.Resource;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Composition;

/// THE engine composition root: the one list of domains in the tree, and every facet answered
/// from it. A domain is declared once, in its own library, with every facet it contributes
/// (DomainModule); the root never collects anything, it lists the domains and answers for a
/// facet, and a consumer asks for the facets it needs and only those:
///
/// - the scene content, EngineSceneComposition (the SceneComposition and AddAllSceneManagers);
/// - the resource modules, deduplicated, their factory descriptions, the type registration
///   and the factories a host's services allow (CreateFactories);
/// - the runtime script surface, EngineScriptSurface, the generated closure of this root.
///
/// Where a facet needs something a domain cannot know (a graphics device), the domain's
/// description names the need and the consumer supplies it through IResourceServices.
static class EngineComposition
{
	/// The prefabs module: Foundation's spawn system and the scene document types, which no
	/// engine library owns, so the root declares it.
	private static DomainModule sPrefabs ~ delete _;
	private static List<DomainModule> sModules ~ delete _;

	/// Every domain, in scene construction order. Built on first use.
	public static List<DomainModule> Modules
	{
		get
		{
			if (sModules == null)
			{
				sPrefabs = new .("prefabs", => PrefabSpawnScene.AddPrefabSpawnSceneManagers, new .(SceneResources.Module));
				sModules = new .()
					{
						sPrefabs,
						ScriptDomain.Module,
						RenderDomain.Module,
						AnimationDomain.Module,
						ParticlesDomain.Module,
						PhysicsDomain.Module,
						TerrainDomain.Module,
						VegetationDomain.Module,
						NavigationDomain.Module,
						AudioDomain.Module,
						UIDomain.Module,
						NetDomain.Module,
						SplineDomain.Module,
						InputDomain.Module
					};
			}
			return sModules;
		}
	}

	/// Every domain's resource modules, each id once, in domain order.
	public static void ResourceModules(List<ResourceModule> outModules)
	{
		for (let domain in Modules)
		{
			for (let module in domain.Resources)
			{
				if (!outModules.Contains(module))
					outModules.Add(module);
			}
		}
	}

	/// Every factory description of every resource module, flattened: readable without
	/// constructing anything. Pointers into the modules, which live for the process.
	public static void FactoryDescriptions(List<ResourceFactoryDesc*> outDescriptions)
	{
		let modules = scope List<ResourceModule>();
		ResourceModules(modules);
		for (let module in modules)
		{
			for (var desc in ref module.Factories)
				outDescriptions.Add(&desc);
		}
	}

	/// Registers every resource module's types into the global serializable registry.
	public static void RegisterResourceTypes()
	{
		let modules = scope List<ResourceModule>();
		ResourceModules(modules);
		for (let module in modules)
			module.RegisterTypes();
	}

	/// Creates into `set` every factory the services allow; the rest are the set's Skipped.
	public static void CreateFactories(ResourceFactorySet set, IResourceServices services)
	{
		let modules = scope List<ResourceModule>();
		ResourceModules(modules);
		set.Create(modules, services);
	}
}
