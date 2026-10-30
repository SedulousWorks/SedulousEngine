using System;
using Sedulous.Content;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain;

/// Opens a TerrainAsset in the terrain page; a page asks for its services when it is made.
class TerrainEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(TerrainAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new TerrainEditorPage(context, mServices.Make(), instance);
}
