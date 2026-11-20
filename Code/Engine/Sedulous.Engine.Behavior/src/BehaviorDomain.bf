using System;
using Sedulous.Engine.Domain;
using Sedulous.Resource;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Behavior;

/// The script domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class BehaviorDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("behavior", => BehaviorScene.AddBehaviorSceneManagers,
		new .(
			ScriptResources.Module)));
	private static DomainModule sModule ~ delete _;
}
