using System;

namespace Sedulous.Editor.Core;

/// One content pak of a dist: the desktop's single pak, or a web build's BC and ASTC
/// siblings, each packed from its own cooked database.
class ContentVariant
{
	/// "" for the single desktop pak, else "bc" or "astc".
	public String Key = new .() ~ delete _;
	/// "Content.pak" / "Content-bc.pak" / "Content-astc.pak".
	public String PakName = new .() ~ delete _;
	/// The absolute cooked database directory to pack from.
	public String CookedDir = new .() ~ delete _;
}
