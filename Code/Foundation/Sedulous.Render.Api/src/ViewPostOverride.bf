namespace Sedulous.Render;

/// Per view post processing overrides for ONE render, which is an editor viewport's show
/// flags.
///
/// Applied ON TOP of the view's resolved configuration and NEVER written back to the scene:
/// a viewport can strip effects for editing clarity, a crisp unjittered image to inspect
/// pixels in or a raw lit one with no bloom, without changing the look the game ships.
struct ViewPostOverride
{
	/// The master switch: drops bloom, occlusion, reflections and antialiasing. Exposure and
	/// tone mapping stay, or the image would not be displayable at all.
	public bool DisablePost = false;

	public bool DisableBloom = false;
	public bool DisableAo = false;
	public bool DisableSsr = false;
	/// Both kinds of antialiasing, which leaves the image crisp and unjittered.
	public bool DisableAa = false;
	public bool DisableSsgi = false;

	/// Draws EVERYTHING in the scene for this view with the frustum test off: the A/B for
	/// what view frustum culling saves. Not post processing, but the same kind of ephemeral
	/// per view switch, so it rides here rather than growing a second override type.
	public bool DisableCulling = false;

	/// The scene pass's multisampling for this view: zero leaves the resolved count alone,
	/// and one, two or four force it. An editor viewport is the source of its own count,
	/// since the scene authors none. Clamped to what the adapter has further down.
	public uint8 MsaaOverride = 0;

	public this() {}
}
