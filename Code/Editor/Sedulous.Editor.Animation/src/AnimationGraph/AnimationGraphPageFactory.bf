using System;
using Sedulous.Content;
using Sedulous.Animation.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Animation;

/// Opens an AnimationGraphAsset in the graph page; a page asks for its services when it is made.
class AnimationGraphPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(AnimationGraphAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new AnimationGraphEditorPage(context, mServices.Make(), instance);
}
