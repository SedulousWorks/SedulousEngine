using System;
using Sedulous.Content;
using Sedulous.Render.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Render;

/// Opens every profile asset in the profile page (the registry matches along the asset type's base
/// chain); a page asks for its services when it is made.
class SettingsProfilePageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(SettingsProfileAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new SettingsProfilePage(context, mServices.Make(), instance);
}

/// The profile page's composition: the asset types' serializables, the editor's own (the preview
/// scene each profile remembers, registered before the app loads the per-project store), and the
/// page.
static class SettingsProfileEditor
{
	/// A page asks `services` (borrowed: the editor's, or a test's, which outlives the context) for
	/// its services when it is made (the window exists by then).
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		RenderPipeline.RegisterAll();
		RenderEditorSerializables.Register();
		context.Pages.Register(new SettingsProfilePageFactory(services));
	}
}
