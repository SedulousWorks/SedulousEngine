using System;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Tests;

/// A builder that declares one extra source file and builds nothing.
class WidgetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(WidgetAsset);
	public Type ProductType => typeof(WidgetAsset);
	public int32 Version => 3;

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		outDeps.AddFile("extra.bin");
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context) => .Ok;
}
