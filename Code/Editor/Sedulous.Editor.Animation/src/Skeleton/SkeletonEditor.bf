using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Animation;

/// The skeleton editor's composition: its page (asking for its services when it is made).
/// Skeletons come from import: there is no creator.
static class SkeletonEditor
{
	/// `services` is borrowed and outlives the page factory.
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		context.Pages.Register(new SkeletonPageFactory(services));
	}
}
