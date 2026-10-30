using System;
using Sedulous.Content;
using Sedulous.Input.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Input;

/// Opens an InputMapAsset in the input map page; a page asks for its services when it is made.
class InputMapPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(InputMapAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new InputMapEditorPage(context, mServices.Make(), instance);
}
