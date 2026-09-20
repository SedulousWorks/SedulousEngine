using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Opens a mesh asset, static or skinned (one factory per type), in the mesh page.
class MeshEditorPageFactory : IEditorPageFactory
{
	private Type mType;
	/// Borrowed.
	private IApplicationHost mHost;
	private UIHost mUiHost;

	public this(Type type, IApplicationHost host, UIHost uiHost)
	{
		mType = type;
		mHost = host;
		mUiHost = uiHost;
	}

	public Type PrimaryType => mType;

	public EditorPage CreatePage(EditorContext context, Instance instance) => new MeshEditorPage(context, mHost, mUiHost, instance);
}
