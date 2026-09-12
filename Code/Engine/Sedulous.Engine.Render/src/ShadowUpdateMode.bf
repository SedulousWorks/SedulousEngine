namespace Sedulous.Engine.Render;

/// How often a local light's shadow is re-rendered.
enum ShadowUpdateMode : uint32
{
	/// Re-rendered every frame.
	case Realtime = 0;
	/// Rendered ONCE into the cached atlas layer, on the assumption that the casters do not
	/// move. The cache refreshes only when the LIGHT itself does, which is what makes it
	/// cheap for a static scene.
	case Static = 1;
}
