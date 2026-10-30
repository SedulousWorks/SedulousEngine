using System;
using Sedulous.Content;
using Sedulous.Script;
using Sedulous.Script.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Script;

/// Opens a ScriptClassAsset in the script page, against the script surface the host bound; a page
/// asks for its services when it is made.
class ScriptClassPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;
	/// Borrowed; null leaves the pages without the bound API.
	private ScriptSurface mSurface;

	/// `services` and `surface` are borrowed and outlive it.
	public this(AssetPageServicesSource services, ScriptSurface surface)
	{
		mServices = services;
		mSurface = surface;
	}

	public Type PrimaryType => typeof(ScriptClassAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new ScriptEditorPage(context, mServices.Make(), instance, mSurface);
}
