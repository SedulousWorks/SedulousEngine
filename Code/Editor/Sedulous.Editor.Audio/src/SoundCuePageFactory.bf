using System;
using Sedulous.Content;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// Opens a SoundCueAsset in the sound cue page; a page asks for its services when it is made.
class SoundCuePageFactory : IEditorPageFactory
{
	/// Borrowed: the editor's (or a test's), which outlives it.
	private AssetPageServicesSource mServices;

	/// `services` is borrowed and outlives it.
	public this(AssetPageServicesSource services)
	{
		mServices = services;
	}

	public Type PrimaryType => typeof(SoundCueAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) =>
		new SoundCueEditorPage(context, mServices.Make(), instance);
}
