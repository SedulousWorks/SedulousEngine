using System;
using Sedulous.Content;
using Sedulous.Heightfield.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Heightfield;

/// Opens a HeightfieldAsset in the heightfield page.
class HeightfieldEditorPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(HeightfieldAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new HeightfieldEditorPage(context, instance);
}
