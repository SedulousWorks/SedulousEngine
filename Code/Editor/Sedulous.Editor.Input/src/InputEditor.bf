using Sedulous.Input.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Input;

/// The input editor's composition: the asset serializables and its page.
static class InputEditor
{
	public static void Register(EditorContext context)
	{
		InputPipeline.RegisterAll();
		context.Pages.Register(new InputMapPageFactory());
	}
}
