using System;
using Sedulous.Content;
using Sedulous.Input.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Input;

/// Opens an InputMapAsset in the input map page.
class InputMapPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(InputMapAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new InputMapEditorPage(context, instance);
}
