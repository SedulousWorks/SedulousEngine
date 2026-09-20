using System;
using Sedulous.Content;
using Sedulous.Runtime.Client;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// Opens an AudioClipAsset in the clip page.
class AudioClipPageFactory : IEditorPageFactory
{
	/// Borrowed.
	private IApplicationHost mHost;

	public this(IApplicationHost host)
	{
		mHost = host;
	}

	public Type PrimaryType => typeof(AudioClipAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new AudioClipEditorPage(context, mHost, instance);
}
