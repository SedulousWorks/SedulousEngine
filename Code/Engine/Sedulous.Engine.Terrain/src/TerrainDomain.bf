using System;
using Sedulous.Engine.Domain;
using Sedulous.Heightfield.Resource;
using Sedulous.Resource;
using Sedulous.Terrain.Resource;

namespace Sedulous.Engine.Terrain;

/// The terrain domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class TerrainDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("terrain", => TerrainScene.AddTerrainSceneManagers,
		new .(
			TerrainResources.Module,
			HeightfieldResources.Module)));
	private static DomainModule sModule ~ delete _;
}
