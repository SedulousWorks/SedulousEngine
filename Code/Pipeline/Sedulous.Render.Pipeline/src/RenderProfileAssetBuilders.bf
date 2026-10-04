using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;

namespace Sedulous.Render.Pipeline;

/// Cooks an Environment Profile to its record by a copy.
class EnvironmentProfileAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(EnvironmentProfileAsset);
	public Type ProductType => typeof(EnvironmentProfileSource);

	/// The sky texture is a runtime reference: its product must exist, but its edits never
	/// re-cook the profile, whose factory binds it at load.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let profile = (EnvironmentProfileAsset)asset;
		if (profile.Values.SkyTexture.Id != Guid.Empty)
			outDeps.References.Add(profile.Values.SkyTexture.Id);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let cooked = scope EnvironmentProfileSource();
		cooked.Values = ((EnvironmentProfileAsset)asset).Values;
		return context.Output.WriteObject(cooked);
	}
}

/// Cooks a Post Process Profile to its record by a copy.
class PostProcessProfileAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(PostProcessProfileAsset);
	public Type ProductType => typeof(PostProcessProfileSource);

	/// The grading lookup texture is a runtime reference, as the environment's sky is.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let profile = (PostProcessProfileAsset)asset;
		if (profile.Values.GradingLut.Id != Guid.Empty)
			outDeps.References.Add(profile.Values.GradingLut.Id);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		let cooked = scope PostProcessProfileSource();
		cooked.Values = ((PostProcessProfileAsset)asset).Values;
		return context.Output.WriteObject(cooked);
	}
}
