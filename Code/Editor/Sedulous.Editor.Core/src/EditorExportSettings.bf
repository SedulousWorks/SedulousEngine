using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The editor level export preferences, a settings section, NOT project local: the
/// templates root override. Non empty wins over $SEDULOUS_TEMPLATES_DIR and the built in
/// <user-data>/templates default, pointing the editor at a shared or checked out templates
/// directory.
[Serializable(1)]
class EditorExportSettings
{
	public String TemplatesRoot = new .() ~ delete _;
}
