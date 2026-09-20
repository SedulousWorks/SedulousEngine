using System;
using Sedulous.Content;
using Sedulous.Texture.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Texture;

/// Opens a TextureAsset in the texture page.
class TextureEditorPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(TextureAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new TextureEditorPage(context, instance);
}
