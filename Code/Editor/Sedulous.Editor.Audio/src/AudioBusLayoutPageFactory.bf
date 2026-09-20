using System;
using Sedulous.Content;
using Sedulous.Audio.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Audio;

/// Opens an AudioBusLayoutAsset in the bus layout page.
class AudioBusLayoutPageFactory : IEditorPageFactory
{
	public Type PrimaryType => typeof(AudioBusLayoutAsset);

	public EditorPage CreatePage(EditorContext context, Instance instance) => new AudioBusLayoutEditorPage(context, instance);
}
