using System;
using Sedulous.Engine.Domain;
using Sedulous.Fonts.Resource;
using Sedulous.Resource;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI;

/// The ui domain's declaration for the engine composition: its scene content and the resource
/// libraries it brings. Built on first use, so no static initialisation order matters.
static class UIDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("ui", => UIScene.AddUISceneManagers,
		new .(
			UIResources.Module,
			FontResources.Module)));
	private static DomainModule sModule ~ delete _;
}
