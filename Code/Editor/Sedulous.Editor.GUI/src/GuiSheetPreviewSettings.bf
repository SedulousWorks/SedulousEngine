using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.GUI;

/// The settings section holding each sheet's preview markup, kept in the project's editor settings
/// (never cooked, never an edit of the sheet).
[Serializable(1)]
class GuiSheetPreviewSettings
{
	public List<GuiSheetPreview> Sheets = new .() ~ DeleteContainerAndItems!(_);

	/// The markup kept for `asset`; null when none was.
	public GuiSheetPreview Find(Guid asset)
	{
		for (let sheet in Sheets)
		{
			if (sheet.Asset == asset)
				return sheet;
		}
		return null;
	}
}

/// One sheet's preview markup, keyed by the sheet asset's guid.
[Serializable(1)]
class GuiSheetPreview
{
	public Guid Asset = .();
	public String Markup = new .() ~ delete _;
}

/// Registers the GUI pages' [Serializable] types (a sheet's kept preview markup), so a settings
/// store can rebuild them from a file.
[SerializableRegistry]
static class GuiEditorSerializables
{
}
