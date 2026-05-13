namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Audio.Resources;
using Sedulous.Resources;

/// Creates a default empty sound cue asset.
class SoundCueAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Sound Cue";
	public StringView Category => "Audio";
	public StringView Extension => ".soundcue";

	public Result<Guid> Create(StringView path, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let res = new SoundCueResource();
		defer delete res;
		res.Name.Set("New Sound Cue");

		let stream = scope FileStream();
		if (stream.Create(path, .Write) case .Err)
			return .Err;
		if (res.WriteToStream(stream, provider) case .Err)
			return .Err;

		return .Ok(res.Id);
	}
}
