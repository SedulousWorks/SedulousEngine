using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Input;
using Sedulous.Input.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Input.Pipeline;

/// Cooks the authored map into its product, VALIDATING first: the editor's save and this cook
/// go through the same check, so a map that saves is a map that cooks.
class InputMapAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(InputMapAsset);
	public Type ProductType => typeof(InputMapResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (InputMapAsset)asset;
		let error = scope String();
		if (!InputMapValidation.Validate(authored.Map, error))
		{
			GlobalLog(.Error, "Cook: the input map is invalid, {}", error);
			return .Err(.InvalidArgument);
		}

		// The cooked resource is the same map behind a product type, so the product BORROWS
		// what the asset owns for the length of the write and gets its own back before its
		// destructor runs. Copying the map instead would buy nothing: the write only reads.
		let cooked = scope InputMapResource();
		let owned = cooked.Map;
		cooked.Map = authored.Map;
		defer { cooked.Map = owned; }

		return context.Output.WriteObject(cooked);
	}
}
