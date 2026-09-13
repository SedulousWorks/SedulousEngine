using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.UI.Pipeline;

/// A stylesheet.
///
/// The stylesheet lives ONLY in the linked source file, never inline.
[Serializable]
class UIThemeAsset : Asset
{
	/// EDITOR ONLY: the markup the theme page previews this stylesheet against, kept so a
	/// theme's preview context survives a session. NEVER read by the builder, so it stays out
	/// of the cooked theme and out of the runtime.
	public String PreviewMarkup = new .() ~ delete _;
}
