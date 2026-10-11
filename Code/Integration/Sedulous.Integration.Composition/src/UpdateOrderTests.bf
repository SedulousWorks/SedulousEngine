using System;
using Sedulous.Scene;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Script;
using Sedulous.Engine.Navigation;

namespace Sedulous.Integration.Composition;

/// The update order across the domains, on a scene composed as a game composes it: the
/// scene's scripts run before the systems that act on what a script writes, so a destination
/// or a graph parameter set in onUpdate takes effect that frame.
class UpdateOrderTests
{
	[Test]
	public static void ScriptsUpdateBeforeTheCrowdAndEverySystemAfterThem()
	{
		let level = scope Scene("level");
		EngineSceneComposition.AddAllSceneManagers(level);
		let scripts = level.GetSystem<ScriptSceneSystem>();
		let crowd = level.GetSystem<NavigationSceneSystem>();
		Test.Assert((scripts != null) && (crowd != null));
		Test.Assert(scripts.UpdateOrder < crowd.UpdateOrder, "an order of their own, not a tie the domain list breaks");

		// Every other system of the scene comes after them, so nothing a script drives has
		// run before it this frame.
		for (let system in level.Systems)
		{
			if (system !== scripts)
				Test.Assert(system.UpdateOrder > scripts.UpdateOrder, scope $"{system.GetType()} runs before the scripts");
		}
	}
}
