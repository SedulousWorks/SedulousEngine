using System;
using Sedulous.Engine.Domain;
using Sedulous.Navigation.Resource;
using Sedulous.Resource;

namespace Sedulous.Engine.Navigation;

/// The navigation domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class NavigationDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("navigation", => NavigationScene.AddNavigationSceneManagers,
		new .(
			NavigationResources.Module)));
	private static DomainModule sModule ~ delete _;
}
