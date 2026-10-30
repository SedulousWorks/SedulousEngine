using System;
using Sedulous.Content;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Generic;

/// The fallback factory. Registered against Object, the root every asset derives from, so
/// nearest-base dispatch lets every bespoke page, a concrete type at distance zero, win. A page asks
/// for its services when it is made (the window exists by then).
class GenericAssetPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(Object);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new GenericAssetEditorPage(context, mServices.Make(), instance);

	/// Registers the fallback, replacing the hard "No editor registered" failure. `services` is
	/// borrowed: the editor's, or a test's, which outlives the context.
	public static void Register(EditorContext context, AssetPageServicesSource services) =>
		context.Pages.Register(new GenericAssetPageFactory(services));
}
