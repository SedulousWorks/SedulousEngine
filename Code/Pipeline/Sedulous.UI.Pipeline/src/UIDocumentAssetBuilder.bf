using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.UI;
using Sedulous.UI.Gamekit;
using Sedulous.UI.Resource;

namespace Sedulous.UI.Pipeline;

/// Cooks a markup document, VALIDATING it on the way through.
///
/// Parsing against the registered control set IS the cook: a document that does not parse
/// fails here rather than at the first frame that tries to show it, and a silently dropped
/// attribute or child surfaces as a warning rather than as nothing at all.
class UIDocumentAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(UIDocumentAsset);
	public Type ProductType => typeof(UIDocumentResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let document = (UIDocumentAsset)asset;
		if (document.FileName.IsEmpty)
		{
			GlobalLog(.Error, "UI: the document has no linked source file, so there is nothing to cook");
			return .Err(.InvalidArgument);
		}

		let markup = scope String();
		if (AssetSource.ReadText(context, document.FileName.Value, markup) case .Err(let readError))
		{
			GlobalLog(.Error, "UI: the document's source file '{}' is missing",
				document.FileName.Value);
			return .Err(readError);
		}
		if (markup.IsEmpty)
		{
			GlobalLog(.Error, "UI: the document is empty, so there is nothing to cook");
			return .Err(.InvalidArgument);
		}

		MarkupLoader.Initialize();
		GamekitMarkup.Register(); // so a screen root validates too

		let warnings = scope List<String>();
		defer { ClearAndDeleteItems!(warnings); }
		let tree = MarkupLoader.LoadFromString(markup, null, warnings);
		if (tree == null)
		{
			GlobalLog(.Error,
				"UI: the document did not parse, being malformed or naming an unknown control");
			return .Err(.InvalidArgument);
		}
		tree.ReleaseRef();

		for (let warning in warnings)
			GlobalLog(.Warning, "UI: the document says {}", warning);

		let cooked = scope UIDocumentResource();
		cooked.Markup.Set(markup);
		return context.Output.WriteObject(cooked);
	}
}
