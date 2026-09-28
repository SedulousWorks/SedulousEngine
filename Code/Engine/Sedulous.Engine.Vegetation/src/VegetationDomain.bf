using System;
using Sedulous.Engine.Domain;
using Sedulous.Resource;
using Sedulous.Vegetation.Resource;

namespace Sedulous.Engine.Vegetation;

/// The vegetation domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class VegetationDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("vegetation", => VegetationScene.AddVegetationSceneManagers,
		new .(
			VegetationResources.Module)));
	private static DomainModule sModule ~ delete _;
}
