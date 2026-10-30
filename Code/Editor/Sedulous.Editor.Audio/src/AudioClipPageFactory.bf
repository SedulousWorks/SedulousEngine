using System;
using Sedulous.Content;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// Opens an AudioClipAsset in the clip page; a page asks for its services when it is made.
class AudioClipPageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(AudioClipAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new AudioClipEditorPage(context, mServices.Make(), instance);
}
