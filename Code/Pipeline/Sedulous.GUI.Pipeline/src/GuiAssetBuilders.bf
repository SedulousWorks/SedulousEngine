using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Pipeline.Core;

namespace Sedulous.GUI.Pipeline;

/// Cooks a linked GUI source after validating it: what cannot be read fails the cook, what was
/// dropped is a warning with its line, and the text goes through to the cooked record. What the
/// source names by guid is the product's runtime reference.
abstract class GuiTextAssetBuilder : IAssetBuilder
{
	public abstract Type AssetType { get; }
	public abstract Type ProductType { get; }

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		if (asset.FileName.IsEmpty)
			return;
		let text = scope String();
		if (AssetSource.ReadText(context, asset.FileName.Value, text) case .Err)
			return;
		GuiPipeline.AddGuidReferences(asset.FileName.Value, text, context, outDeps.References, false);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		if (asset.FileName.IsEmpty)
		{
			GlobalLog(.Error, "GUI: a GUI asset has no linked source file, cook failed");
			return .Err(.InvalidArgument);
		}
		let file = asset.FileName.Value;
		let text = scope String();
		if (AssetSource.ReadText(context, file, text) case .Err(let readError))
		{
			GlobalLog(.Error, "GUI: '{}': source file missing, cook failed", file);
			return .Err(readError);
		}
		let said = scope List<GuiDiagnostic>();
		defer { ClearAndDeleteItems!(said); }
		let readable = Validate(text, said);
		GuiPipeline.LogDiagnostics(file, said);
		if (!readable)
		{
			GlobalLog(.Error, "GUI: '{}' cannot be read, cook failed", file);
			return .Err(.InvalidArgument);
		}
		let references = scope List<Guid>();
		GuiPipeline.AddGuidReferences(file, text, context, references, true);
		return Write(text, context);
	}

	/// Whether `text` can be read, what it dropped added to `said`.
	protected abstract bool Validate(StringView text, List<GuiDiagnostic> said);

	/// Writes the cooked record holding `text` to the context's output.
	protected abstract Result<void, ErrorCode> Write(StringView text, AssetBuildContext context);
}

/// A `.gml` document, cooked to a GuiDocumentSource.
class GuiDocumentAssetBuilder : GuiTextAssetBuilder
{
	public override Type AssetType => typeof(GuiDocumentAsset);
	public override Type ProductType => typeof(GuiDocumentSource);

	protected override bool Validate(StringView text, List<GuiDiagnostic> said) => GuiPipeline.ValidateDocument(text, said);

	protected override Result<void, ErrorCode> Write(StringView text, AssetBuildContext context)
	{
		let cooked = scope GuiDocumentSource();
		cooked.Markup.Set(text);
		return context.Output.WriteObject(cooked);
	}
}

/// A `.css` style sheet, cooked to a GuiStyleSheetSource. A sheet always reads.
class GuiStyleSheetAssetBuilder : GuiTextAssetBuilder
{
	public override Type AssetType => typeof(GuiStyleSheetAsset);
	public override Type ProductType => typeof(GuiStyleSheetSource);

	protected override bool Validate(StringView text, List<GuiDiagnostic> said)
	{
		GuiPipeline.ValidateStyleSheet(text, said);
		return true;
	}

	protected override Result<void, ErrorCode> Write(StringView text, AssetBuildContext context)
	{
		let cooked = scope GuiStyleSheetSource();
		cooked.Css.Set(text);
		return context.Output.WriteObject(cooked);
	}
}
