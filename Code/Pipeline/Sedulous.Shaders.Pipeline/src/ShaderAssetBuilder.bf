using System;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Shaders.Resource;

namespace Sedulous.Shaders.Pipeline;

/// Reads both source files and inlines them into the cooked shader.
class ShaderAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(ShaderAsset);
	public Type ProductType => typeof(ShaderSource);

	/// The fragment file is a SECOND source input, the vertex one being the implicit file name,
	/// so editing it has to dirty this shader's recipe hash.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let shader = (ShaderAsset)asset;
		if (!shader.FragmentFile.IsEmpty)
			outDeps.AddFile(shader.FragmentFile);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let shader = (ShaderAsset)asset;
		let cooked = scope ShaderSource();
		cooked.Name.Set(shader.Name);

		if (AssetSource.ReadText(context, shader.FileName.Value, cooked.VertexSource)
			case .Err(let vertexError))
		{
			return .Err(vertexError);
		}
		if (AssetSource.ReadText(context, shader.FragmentFile, cooked.FragmentSource)
			case .Err(let fragmentError))
		{
			return .Err(fragmentError);
		}

		return context.Output.WriteObject(cooked);
	}
}
