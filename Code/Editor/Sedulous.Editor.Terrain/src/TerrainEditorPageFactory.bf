using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// Opens a TerrainAsset in the terrain page.
class TerrainEditorPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(TerrainAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new TerrainEditorPage(context, mHost, mUiHost, instance);
}
