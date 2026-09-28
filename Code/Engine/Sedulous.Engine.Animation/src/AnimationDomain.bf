using System;
using Sedulous.Animation.Resource;
using Sedulous.Engine.Domain;
using Sedulous.PropertyAnimation.Resource;
using Sedulous.Resource;

namespace Sedulous.Engine.Animation;

/// The animation domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class AnimationDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("animation", => AnimationScene.AddAnimationSceneManagers,
		new .(
			AnimationResources.Module,
			PropertyAnimationResources.Module)));
	private static DomainModule sModule ~ delete _;
}
