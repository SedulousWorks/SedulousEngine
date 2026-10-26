using System;
using Sedulous.Engine.Domain;
using Sedulous.Fonts.Resource;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.VG.Resource;

namespace Sedulous.Engine.GUI;

/// The gui domain's declaration for the engine composition: its scene content and the resource
/// libraries it brings, beside the ui domain's while both live. Built on first use, so no static
/// initialisation order matters.
static class GuiDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("gui", => GuiScene.AddGuiSceneManagers,
		new .(
			// The documents and the sheets the components name.
			GuiResources.Module,
			// Vector images: what a sheet's icons are cooked from.
			VGResources.Module,
			FontResources.Module)));
	private static DomainModule sModule ~ delete _;
}
