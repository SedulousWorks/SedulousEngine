using System;
using Sedulous.Content;
using Sedulous.Physics.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Physics;

/// Opens a CollisionShapeAsset in the collision shape page; a page asks for its services when it
/// is made.
class CollisionShapeEditorPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(CollisionShapeAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new CollisionShapeEditorPage(context, mServices.Make(), instance);
}
