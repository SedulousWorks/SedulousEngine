namespace Sedulous.Editor.Core;

/// A cheap per instance cook state for the Assets panel, no recipe recompute; exact
/// dirtiness is the driver's business at cook time.
enum CookBadge : uint8
{
	/// The instance's type has no registered builder: a scene, raw data.
	NoBuilder,
	/// A record and a product exist; a stale recipe still shows Cooked until the next cook.
	Cooked,
	/// No record or no product yet: never cooked, or swept.
	Missing,
	/// The last cook of this asset failed; the console has the log.
	Failed
}
