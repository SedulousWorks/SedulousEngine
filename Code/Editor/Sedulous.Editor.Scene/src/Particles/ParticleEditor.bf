using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Particles;
using Sedulous.Particles.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The particle editor's composition: the asset and module serializables, its page and the
/// "Particle Effect" creator.
static class ParticleEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		ParticleModules.RegisterModules();
		ParticlesPipeline.RegisterAll();
		context.Pages.Register(new ParticleEffectPageFactory(host, uiHost));
		context.RegisterCreator(new AssetCreator("Particle Effect", "", new (ctx, group) => ParticleAssetCreators.CreateParticleEffectInstance(ctx, group)));
	}
}
