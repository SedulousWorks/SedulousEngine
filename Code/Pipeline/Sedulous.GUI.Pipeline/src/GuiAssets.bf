using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.GUI.Pipeline;

/// A GUI document: a LINKED `.xml` in the sources tree. The markup lives only in that file.
[DisplayName("GUI Document")]
[Category("GUI")]
[Serializable]
class GuiDocumentAsset : Asset
{
}

/// A GUI style sheet: a LINKED `.css` in the sources tree.
[DisplayName("GUI Style Sheet")]
[Category("GUI")]
[Serializable]
class GuiStyleSheetAsset : Asset
{
	/// EDITOR ONLY: the markup the sheet's page previews it against, kept so its preview survives
	/// a session. Never read by the builder, so it stays out of the cooked sheet.
	public String PreviewMarkup = new .() ~ delete _;
}
