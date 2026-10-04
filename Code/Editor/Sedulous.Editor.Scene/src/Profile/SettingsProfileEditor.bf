using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Render.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens every profile asset in the profile page: the registry matches along the asset type's
/// base chain.
class SettingsProfilePageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(SettingsProfileAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new SettingsProfilePage(context, mHost, mUiHost, instance);
}

/// The profile page's composition: the asset types' serializables and the page.
static class SettingsProfileEditor
{
	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		RenderPipeline.RegisterAll();
		context.Pages.Register(new SettingsProfilePageFactory(host, uiHost));
	}
}
