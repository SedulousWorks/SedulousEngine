using System;
using Sedulous.Audio.Resource;
using Sedulous.Engine.Domain;
using Sedulous.Resource;

namespace Sedulous.Engine.Audio;

/// The audio domain's declaration for the engine composition: its scene content and the
/// resource libraries it brings. Built on first use, so no static initialisation order matters.
static class AudioDomain
{
	public static DomainModule Module => sModule ?? (sModule = new .("audio", => AudioScene.AddAudioSceneManagers,
		new .(
			AudioResources.Module)));
	private static DomainModule sModule ~ delete _;
}
