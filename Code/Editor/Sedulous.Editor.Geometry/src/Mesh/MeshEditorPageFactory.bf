using System;
using Sedulous.Content;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Geometry;

/// Opens a mesh asset, static or skinned (one factory per type), in the mesh viewer; a page asks
/// for its services when it is made.
class MeshEditorPageFactory : IEditorPageFactory
{
	private Type mType;
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(Type type, AssetPageServicesSource services)
	{
		mType = type;
		mServices = services;
	}

	public Type PrimaryType => mType;

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new MeshEditorPage(context, mServices.Make(), instance, mType);
}
