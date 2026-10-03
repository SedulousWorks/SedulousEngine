using System;
using Sedulous.Core;
using Sedulous.Engine.Composition;
using Sedulous.Fonts.Resource;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The runtime's factory set is the engine composition's: attaching a manager registers every
/// factory the composition describes and this host's services allow.
///
/// The incident the pins guard: a factory existed and was tested on its own, but NO host ever
/// registered it, so binding that product failed silently in every runtime. It was masked in
/// the editor by a development tree fallback and visible only in an export, which has no source
/// tree. The count is the composition's now, so a factory a domain declares can no longer be
/// left behind; the pins keep the incident's class of failure loud.
class StandardFactoriesTests
{
	[Test]
	public static void AttachingAManagerRegistersTheCompositionsHeadlessSetWithThePins()
	{
		// No database: nothing here resolves an asset, and the set of factories is what is
		// being measured.
		let resources = scope ResourceManager(null);
		let host = scope StubHost();

		let app = scope DefaultApplication();
		app.AttachResourceManager(resources, host);

		// The runtime's set IS the composition's headless set: what a host with no device and
		// no shader system can create. A factory a domain declares is in both by construction.
		let headless = scope ResourceFactorySet();
		EngineComposition.CreateFactories(headless, scope NoResourceServices());
		let descriptions = scope System.Collections.List<ResourceFactoryDesc*>();
		EngineComposition.FactoryDescriptions(descriptions);
		Test.Assert(resources.FactoryCount == headless.Count, scope $"{resources.FactoryCount} factories");
		Test.Assert(resources.FactoryCount == descriptions.Count - 2);
		for (let factory in headless.Factories)
			Test.Assert(resources.HasFactory(factory.ProductTypeId));
		// And the app reports the two it skipped, each by the service it wanted.
		Test.Assert(app.Factories.Skipped.Length == 2);

		// The incident pin: the cooked default interface font must be constructible in every
		// runtime host, a shipped player having no development tree to fall back on.
		Test.Assert(resources.HasFactory(ResourceManager.ProductTypeIdOf<Font>()));

		// The terrain pins: a cooked terrain binds its whole CPU reference chain, being the
		// bundle, the grid and the splat raster.
		Test.Assert(resources.HasFactory(ResourceManager.ProductTypeIdOf<TerrainResource>()));
		Test.Assert(resources.HasFactory(ResourceManager.ProductTypeIdOf<Heightfield>()));
		Test.Assert(resources.HasFactory(ResourceManager.ProductTypeIdOf<SplatWeights>()));

		// And the device gating, documented: no graphics device on the host means no texture
		// factory.
		Test.Assert(!resources.HasFactory(ResourceManager.ProductTypeIdOf<Texture>()));
	}

	/// Shutdown destroys the factories while the device is alive (the texture factory holds
	/// it), not with the application. A borrowed manager outlives the application, so it is
	/// left holding none of them rather than pointers to destroyed ones.
	[Test]
	public static void ShutdownDestroysTheFactoriesAndABorrowedManagerForgetsThem()
	{
		let resources = scope ResourceManager(null);
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.AttachResourceManager(resources, host);
		Test.Assert(resources.FactoryCount > 0);
		Test.Assert(app.Factories.Count == resources.FactoryCount);

		app.OnShutdown(host);
		Test.Assert(app.Factories.Count == 0);
		Test.Assert(resources.FactoryCount == 0);
		Test.Assert(!resources.HasFactory(ResourceManager.ProductTypeIdOf<Font>()));
	}
}
