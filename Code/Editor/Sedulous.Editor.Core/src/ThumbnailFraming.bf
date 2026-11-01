using Sedulous.Core;

namespace Sedulous.Editor.Core;

/// How the stage views a staged job. The default is an orthographic camera along (1,1,1)
/// aimed at Center, sized from Radius. A generator with a view of its own (a scene document,
/// as its page last showed it) sets HasView with that camera's View and Projection (a square
/// aspect), its Eye and its FarZ, and the stage renders through it instead. PrewarmSteps
/// simulation ticks, 1/60 s each, run before the render, for content that is empty at t=0:
/// particles.
struct ThumbnailFraming
{
	public Float3 Center = .Zero;
	public float Radius = 1.0f;
	public bool HasView = false;
	public Float4x4 View = .Identity();
	public Float4x4 Projection = .Identity();
	public Float3 Eye = .Zero;
	public float FarZ = 1000.0f;
	public uint32 PrewarmSteps = 0;
}
