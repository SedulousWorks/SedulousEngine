using System;
using Sedulous.Core;
using Sedulous.Fonts.Resource;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The standard factory set's COVERAGE TRIPWIRE.
///
/// The incident this pins: a factory existed and was tested on its own, but NO host ever
/// registered it, so binding that product failed silently in every runtime. It was masked in
/// the editor by a development tree fallback and visible only in an export, which has no
/// source tree. A count plus the specific pins make the next missing registration fail HERE,
/// and loudly.
class StandardFactoriesTests
{
	[Test]
	public static void TheStandardFactorySetIsComplete()
	{
		// No database: nothing here resolves an asset, and the set of factories is what is
		// being measured.
		let resources = scope ResourceManager(null);
		let host = scope StubHost();

		let app = scope DefaultApplication();
		app.AttachResourceManager(resources, host);

		// COUNT TRIPWIRE: the standard headless set, which has no texture factory because it
		// has no device. A new standard factory bumps this DELIBERATELY, and a lost
		// registration fails loudly here rather than as a silent null bind in a shipped game.
		const int cStandardHeadlessFactoryCount = 24; // + ScriptClassFactory
		Test.Assert(resources.FactoryCount == cStandardHeadlessFactoryCount);

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
}
