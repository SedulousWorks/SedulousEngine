using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The skeleton editor's composition: its page.
static class SkeletonEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		context.Pages.Register(new SkeletonPageFactory(host, uiHost));
	}
}
