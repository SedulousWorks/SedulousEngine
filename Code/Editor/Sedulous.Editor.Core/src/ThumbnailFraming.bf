using Sedulous.Core;

namespace Sedulous.Editor.Core;

/// How the stage views a staged job. The default is an orthographic camera along (1,1,1)
/// aimed at Center, sized from Radius. PreferSceneCamera asks for the scene's own primary
/// camera when one exists, so a scene document looks like itself, the framing staying the
/// fallback. PrewarmSteps simulation ticks, 1/60 s each, run before the render, for content
/// that is empty at t=0: particles.
struct ThumbnailFraming
{
	public Float3 Center = .Zero;
	public float Radius = 1.0f;
	public bool PreferSceneCamera = false;
	public uint32 PrewarmSteps = 0;
}
