using System;
using Sedulous.Content;
using Sedulous.Fonts.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Fonts;

/// Opens a FontAsset in the font page.
class FontEditorPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(FontAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new FontEditorPage(context, instance);
}
