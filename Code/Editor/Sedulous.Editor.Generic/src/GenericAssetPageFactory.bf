using System;
using Sedulous.Content;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Generic;

/// The fallback factory. Registered against Object, the root every asset derives from, so
/// nearest-base dispatch lets every bespoke page, a concrete type at distance zero, win.
class GenericAssetPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(Object);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new GenericAssetEditorPage(context, instance);

	/// Registers the fallback, replacing the hard "No editor registered" failure.
	public static void Register(EditorContext context) => context.Pages.Register(new GenericAssetPageFactory());
}
