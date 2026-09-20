using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The animation clip editor's composition: the asset serializables, the preview preference
/// section and its page.
static class AnimationClipEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		AnimationPipeline.RegisterAll();
		SceneEditorSerializables.RegisterAll();
		context.Pages.Register(new AnimationClipPageFactory(host, uiHost));
	}
}
