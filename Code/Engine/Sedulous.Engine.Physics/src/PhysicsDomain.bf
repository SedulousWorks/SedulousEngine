using System;
using Sedulous.Engine.Domain;
using Sedulous.Physics.Resource;
using Sedulous.Resource;

namespace Sedulous.Engine.Physics;

/// The physics domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class PhysicsDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("physics", => PhysicsScene.AddPhysicsSceneManagers,
		new .(
			PhysicsResources.Module)));
	private static DomainModule sModule ~ delete _;
}
