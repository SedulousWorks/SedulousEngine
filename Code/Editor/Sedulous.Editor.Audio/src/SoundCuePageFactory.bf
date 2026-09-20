using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// Opens a SoundCueAsset in the sound cue page.
class SoundCuePageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;

	public this(IApplicationHost host)
	{
		mHost = host;
	}

	public Type PrimaryType => typeof(SoundCueAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new SoundCueEditorPage(context, mHost, instance);
}
