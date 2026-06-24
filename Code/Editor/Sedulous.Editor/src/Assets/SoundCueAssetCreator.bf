namespace Sedulous.Editor;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Audio.Resources;
using Sedulous.Resources;
using Sedulous.VFS;

/// Creates a default empty sound cue asset.
class SoundCueAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Sound Cue";
	public StringView Category => "Audio";
	public StringView Extension => ".soundcue";

	public Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			context.Logger?.LogError("SoundCue create: no serializer provider");
			return .Err;
		}

		let res = new SoundCueResource();
		defer delete res;
		res.Name.Set("New Sound Cue");

		let stream = scope MemoryStream();
		if (res.WriteToStream(stream, provider) case .Err)
		{
			context.Logger?.LogError("SoundCue create: serialization failed for {}", locator);
			return .Err;
		}
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err(let err))
		{
			context.Logger?.LogError("SoundCue create: mount save failed for {}: {}", locator, err);
			return .Err;
		}

		context.Logger?.LogInformation("SoundCue created: {}", locator);
		return .Ok(res.Id);
	}
}
