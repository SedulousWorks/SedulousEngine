using System;
using Sedulous.Engine.Domain;
using Sedulous.Particles.Resource;
using Sedulous.Resource;

namespace Sedulous.Engine.Particles;

/// The particles domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class ParticlesDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("particles", => ParticleScene.AddParticleSceneManagers,
		new .(
			ParticleResources.Module)));
	private static DomainModule sModule ~ delete _;
}
