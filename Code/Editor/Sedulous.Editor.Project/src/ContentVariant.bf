using System;

namespace Sedulous.Editor.Project;

/// One content pak of a dist: the desktop's single pak, a web build's BC and ASTC siblings,
/// or an Android build's ASTC pak, each packed from its own cooked database.
class ContentVariant
{
	/// "" for the single desktop pak, else "bc", "astc" or "android".
	public String Key = new .() ~ delete _;
	/// "Content.pak" / "Content-bc.pak" / "Content-astc.pak".
	public String PakName = new .() ~ delete _;
	/// The absolute cooked database directory to pack from.
	public String CookedDir = new .() ~ delete _;
	/// The cook target its products are cooked for ("web-bc", "android"); empty: the host's.
	public String TargetId = new .() ~ delete _;
}
