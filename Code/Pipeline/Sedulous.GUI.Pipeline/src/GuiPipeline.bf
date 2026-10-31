using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.Pipeline.Core;

namespace Sedulous.GUI.Pipeline;

// The GUI's sources, cooked (tooling: never linked by the runtime, nor in a web or shipping build).
// Sedulous.UI's counterpart: Sedulous.UI.Pipeline.
//
// * GuiDocumentAsset (`.xml` markup) and GuiStyleSheetAsset (`.css`): a LINKED source file in the
//   project's sources tree (Asset.FileName), as a script's; an asset with no linked file fails the
//   cook.
// * The builders VALIDATE: a document through the GUI's markup loader with every element type the
//   tools register (the core's, the gamekit's, the toolkit's, the code editor's), a sheet through
//   the CSS parser and the check of its property names. What cannot be read fails the cook (markup
//   that does not parse); what was dropped (an unknown element or attribute, an at-rule, a property
//   no style or element takes) is a warning, each with its file and line where known. The text then
//   goes through to the cooked record (Sedulous.GUI.Resources).
// * What a document or a sheet names by asset guid (`url("{guid}")`, `source="{guid}"`, a document
//   pushed by its guid) is recorded as a runtime reference of the product; a guid naming no asset is
//   a warning.
// * One importer takes a dropped `.xml` or `.css` into the sources tree and links it; creators make
//   a new one from starter text (File > New, MCP's asset_create).

/// Registration for the GUI's authoring types, and what their cooks share.
[SerializableRegistry]
static class GuiPipeline
{
	public const String cDocumentStarter =
		"""
		<Panel class="page" flex-direction="column" align-items="center" gap="12" padding="24">
		    <Label id="title" text="New document"/>
		    <Button id="ok" text="OK"/>
		</Panel>

		""";

	public const String cStyleSheetStarter =
		"""
		/* A game's sheet over the GUI's theme: set its tokens, or style elements and classes. */
		:root { --accent: #f3a047; }
		.page { background-color: var(--surface); }

		""";

	/// Registers every element type a GUI document may name, once (the tools' set).
	public static void RegisterValidationElements()
	{
		RegisterGuiElements();
		RegisterGamekitElements();
		RegisterToolkitElements();
		RegisterCodeElements();
	}

	/// Validates `markup` as a cook does: false when it cannot be read; what was dropped, and the
	/// reason it failed, added to `outDiagnostics` (the caller owns them).
	public static bool ValidateDocument(StringView markup, List<GuiDiagnostic> outDiagnostics)
	{
		RegisterValidationElements();
		let elements = scope ElementSet();
		let loader = scope MarkupLoader(elements);
		loader.SetDiagnostics(outDiagnostics);
		let tree = loader.LoadFromString(markup);
		if (tree == null)
			return false;
		tree.ReleaseRef();
		return true;
	}

	/// Validates `css` as a cook does: what the parser skipped and the property names nothing takes,
	/// added to `outDiagnostics`. A sheet always reads (the parser is best effort): its problems are
	/// warnings.
	public static void ValidateStyleSheet(StringView css, List<GuiDiagnostic> outDiagnostics)
	{
		RegisterValidationElements();
		let sheet = scope StyleSheet();
		CSSParser.Parse(css, default, outDiagnostics, sheet);
		CheckStyleSheetNames(sheet, outDiagnostics);
	}

	/// The asset guids `text` names (`{xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}`), each once, in order.
	public static void FindGuidReferences(StringView text, List<Guid> outFound)
	{
		const int cForm = 36; // the canonical spelling, braces aside
		for (int i = 0; i + cForm + 1 < text.Length; i++)
		{
			if ((text[i] != '{') || (text[i + cForm + 1] != '}'))
				continue;
			if (!(Guid.Parse(text.Substring(i + 1, cForm)) case .Ok(let id)))
				continue;
			if (!outFound.Contains(id))
				outFound.Add(id);
			i += cForm + 1;
		}
	}

	/// Says each diagnostic into the log with its asset's file and line.
	public static void LogDiagnostics(StringView file, List<GuiDiagnostic> said)
	{
		for (let d in said)
			GlobalLog((d.Level == .Error) ? .Error : .Warning, "GUI: {}:{}: {}", file, d.Line, d.Message);
	}

	/// The guids `text` names that are assets of the source or cooked database, added to `outIds`;
	/// the others are warned of when `warn`.
	public static void AddGuidReferences(StringView file, StringView text, AssetBuildContext context, List<Guid> outIds, bool warn)
	{
		let found = scope List<Guid>();
		FindGuidReferences(text, found);
		for (let id in found)
		{
			let known = ((context.SourceDatabase != null) && (context.SourceDatabase.GetInstance(id) != null)) ||
				((context.Database != null) && (context.Database.GetInstance(id) != null));
			if (known)
				outIds.Add(id);
			else if (warn)
				GlobalLog(.Warning, "GUI: {}: names the guid {}, which is no asset", file, id);
		}
	}
}
