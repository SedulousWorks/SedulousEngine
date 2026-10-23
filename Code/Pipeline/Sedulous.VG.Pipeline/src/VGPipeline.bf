using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.VG.Resource;

namespace Sedulous.VG.Pipeline;

/// Registration for the vector graphics authoring types, and what another cook reads a vector
/// image through.
[SerializableRegistry]
static class VGPipeline
{
	/// The SVG a vector image asset carries: its cooked product when the cook has made it,
	/// else its linked source file (a headless or source database cook). NotFound when `id`
	/// names no vector image. What a UI theme's `@icon` embeds.
	public static Result<void, ErrorCode> ReadVectorImage(AssetBuildContext context, Guid id, String outSvg)
	{
		for (let database in IContentDatabase[?](context.Database, context.SourceDatabase))
		{
			if (database == null)
				continue;
			let instance = database.GetInstance(id);
			if (instance == null)
				continue;
			let object = instance.ReadObject();
			defer delete object;
			if (let cooked = object as VectorImageResource)
			{
				outSvg.Set(cooked.Svg);
				return .Ok;
			}
			if (let asset = object as VectorImageAsset)
				return AssetSource.ReadText(context, asset.FileName.Value, outSvg);
		}
		return .Err(.NotFound);
	}
}
