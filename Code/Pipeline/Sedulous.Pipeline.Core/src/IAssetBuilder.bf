using System;
using Sedulous.Core;

namespace Sedulous.Pipeline.Core;

/// Cooks one source asset type into a runtime resource.
///
/// Tooling only. The player links no builder; it loads what one produced.
interface IAssetBuilder
{
	/// The source asset type this builder handles.
	Type AssetType { get; }

	/// The cooked resource type it writes. The driver stamps output instances with it.
	Type ProductType { get; }

	/// The cook logic's version. BUMP IT whenever Build's output changes for inputs that did
	/// not, because it is folded into the recipe hash and is what re-cooks exactly this
	/// builder's products. Forgetting the bump is the known failure mode, and rebuilding
	/// everything is the only hammer left once it happens.
	int32 Version => 1;

	/// Whether this builder's product varies per export target. Invariant by default.
	BuildVariance Variance => .PlatformInvariant;

	/// Declares what this build consumes beyond the asset's own file name. Nothing by default.
	void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
	}

	/// Cooks the asset into the context's output instance.
	Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context);
}
