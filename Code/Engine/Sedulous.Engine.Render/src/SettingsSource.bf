using Sedulous.Core;

namespace Sedulous.Engine.Render;

/// Where a scene settings block's values come from: the scene's own, stored with the scene, or
/// a shared profile asset the block references. The values live in one place, chosen by this,
/// so nothing is copied between them.
[Scriptable(.AllPublic)]
enum SettingsSource : uint32
{
	case Scene;
	case Profile;
}
