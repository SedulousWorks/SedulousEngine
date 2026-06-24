namespace Sedulous.Editor;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Resources;
using Sedulous.VFS;

/// Creates a default empty animation graph asset.
class AnimGraphAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Animation Graph";
	public StringView Category => "Animation";
	public StringView Extension => ".animgraph";

	public Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			context.Logger?.LogError("AnimGraph create: no serializer provider");
			return .Err;
		}

		let graph = new AnimationGraph();
		let res = new AnimationGraphResource(graph, true);
		defer delete res;
		res.Name.Set("New Animation Graph");

		let stream = scope MemoryStream();
		if (res.WriteToStream(stream, provider) case .Err)
		{
			context.Logger?.LogError("AnimGraph create: serialization failed for {}", locator);
			return .Err;
		}
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err(let err))
		{
			context.Logger?.LogError("AnimGraph create: mount save failed for {}: {}", locator, err);
			return .Err;
		}

		context.Logger?.LogInformation("AnimGraph created: {}", locator);
		return .Ok(res.Id);
	}
}
