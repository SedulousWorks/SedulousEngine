namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Resources;

/// Creates a default empty property animation clip asset.
class PropAnimAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Property Animation";
	public StringView Category => "Animation";
	public StringView Extension => ".propanim";

	public Result<Guid> Create(StringView path, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let clip = new PropertyAnimationClip();
		let res = new PropertyAnimationClipResource(clip, true);
		defer delete res;
		res.Name.Set("New Property Animation");

		let stream = scope FileStream();
		if (stream.Create(path, .Write) case .Err)
			return .Err;
		if (res.WriteToStream(stream, provider) case .Err)
			return .Err;

		return .Ok(res.Id);
	}
}
