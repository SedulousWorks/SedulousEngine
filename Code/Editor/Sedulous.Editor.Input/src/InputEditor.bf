using Sedulous.Input.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Input;

/// The input editor's composition: the asset serializables and its page.
static class InputEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		InputPipeline.RegisterAll();
		context.Pages.Register(new InputMapPageFactory(services));
	}
}
