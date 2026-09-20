using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The animation graph editor's composition: the asset serializables, the preview
/// preference section, its page and the "Animation Graph" creator.
static class AnimationGraphEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		AnimationPipeline.RegisterAll();
		SceneEditorSerializables.RegisterAll();
		context.Pages.Register(new AnimationGraphPageFactory(host, uiHost));
		context.RegisterCreator(new AssetCreator("Animation Graph", "Animation", new (ctx, group) => AnimationGraphAssetCreators.CreateAnimationGraphInstance(ctx, group)));
	}
}
