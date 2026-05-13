namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Resources;

/// Creates a default empty animation graph asset.
class AnimGraphAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Animation Graph";
	public StringView Category => "Animation";
	public StringView Extension => ".animgraph";

	public Result<Guid> Create(StringView path, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let graph = new AnimationGraph();
		let res = new AnimationGraphResource(graph, true);
		defer delete res;
		res.Name.Set("New Animation Graph");

		let stream = scope FileStream();
		if (stream.Create(path, .Write) case .Err)
			return .Err;
		if (res.WriteToStream(stream, provider) case .Err)
			return .Err;

		return .Ok(res.Id);
	}
}
