namespace Sedulous.Texture.Compression;

/// The compressed texture FAMILIES an export target's devices support.
///
/// A capability, never a platform: the question this answers is "what families does this
/// target support", not "which platform is this".
struct TargetProfile
{
	/// BC1 through BC7, which desktops and desktop browsers have.
	public bool Bc = false;
	/// ASTC, which mobile browsers have instead.
	public bool Astc = false;
	/// ETC2. Encoding is not implemented, so selecting it falls back to uncompressed.
	public bool Etc2 = false;

	public this() {}
	public this(bool bc, bool astc, bool etc2)
	{
		Bc = bc;
		Astc = astc;
		Etc2 = etc2;
	}

	/// The always warm host desktop profile, which is BC capable.
	public static TargetProfile Desktop => .(true, false, false);

	/// The mobile web profile: mobile browsers expose ASTC rather than BC, so a web export
	/// cooks this alongside the desktop BC variant.
	public static TargetProfile Mobile => .(false, true, false);
}
