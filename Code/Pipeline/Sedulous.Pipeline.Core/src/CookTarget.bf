using System;

namespace Sedulous.Pipeline.Core;

/// The export target a cook is producing for.
///
/// The identifier is BOTH the per target cooked database's directory name AND the recipe's
/// platform salt, so a variant product re-cooks when the target changes.
///
/// The capability flags describe the compressed texture families the target's DEVICES support.
/// A variant builder maps them onto its encoder profile and never keys on the identifier or a
/// platform name: the rule is capability, never platform, because the same platform ships
/// devices that differ.
struct CookTarget
{
	/// BORROWED. Every identifier in use is a literal that outlives the cook, so the target
	/// costs no allocation to pass around.
	public StringView Id = "host";

	/// BC1 through BC7: desktops and desktop browsers.
	public bool Bc = true;
	/// ASTC: mobile browsers.
	public bool Astc = false;
	/// ETC2, which nothing encodes yet.
	public bool Etc2 = false;

	public this() {}
	public this(StringView id, bool bc, bool astc, bool etc2)
	{
		Id = id;
		Bc = bc;
		Astc = astc;
		Etc2 = etc2;
	}

	/// The always warm target the editor's development loop cooks against, which is a BC
	/// capable desktop.
	public static CookTarget Host => .("host", true, false, false);

	/// The capability profile for a target identifier.
	///
	/// A web export splits into two variants: desktop browsers, which have BC, and mobile
	/// browsers, which have ASTC instead. Everything else, including unknown identifiers,
	/// is BC capable desktop. New targets extend this, still keyed on capability.
	public static CookTarget For(StringView id)
	{
		if (id == "web-astc")
			return .(id, false, true, false);
		return .(id, true, false, false);
	}
}
