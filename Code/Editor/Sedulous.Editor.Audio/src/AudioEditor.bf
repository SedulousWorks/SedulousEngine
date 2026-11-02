using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// The audio editor's composition: the asset serializables, the clip, sound cue and bus layout
/// pages, the sound files' import preview, and the clip thumbnails when the context has a
/// thumbnail service.
static class AudioEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		AudioPipeline.RegisterAll();
		context.Pages.Register(new AudioClipPageFactory(services));
		context.Pages.Register(new SoundCuePageFactory(services));
		context.Pages.Register(new AudioBusLayoutPageFactory(services));
		context.ImportPreviews.Register(new SoundFilePreviewFactory(typeof(AudioClipAsset), services));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new AudioClipThumbnailGenerator());
	}
}
