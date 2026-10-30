using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Animation;

/// The animation clip editor's composition: the asset serializables, the preview preference
/// section and its page (asking for its services when it is made).
static class AnimationClipEditor
{
	/// `services` is borrowed and outlives the page factory.
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		AnimationPipeline.RegisterAll();
		AnimationEditorSerializables.Register();
		context.Pages.Register(new AnimationClipPageFactory(services));
	}
}
