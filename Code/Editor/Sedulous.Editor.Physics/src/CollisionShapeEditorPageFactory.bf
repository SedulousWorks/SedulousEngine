using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Physics.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Physics;

/// Opens a CollisionShapeAsset in the collision shape page.
class CollisionShapeEditorPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(IApplicationHost host, UIHost uiHost)
	{
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => typeof(CollisionShapeAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new CollisionShapeEditorPage(context, mHost, mUiHost, instance);
}
