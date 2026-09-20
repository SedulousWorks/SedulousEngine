using Sedulous.Runtime.Client;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// The audio editor's composition: the asset serializables, the clip, sound cue and bus
/// layout pages, and the clip thumbnail when the context has a thumbnail service.
static class AudioEditor
{
	public static void Register(EditorContext context, IApplicationHost host)
	{
		AudioPipeline.RegisterAll();
		context.Pages.Register(new AudioClipPageFactory(host));
		context.Pages.Register(new SoundCuePageFactory(host));
		context.Pages.Register(new AudioBusLayoutPageFactory());
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new AudioClipThumbnailGenerator());
	}
}
