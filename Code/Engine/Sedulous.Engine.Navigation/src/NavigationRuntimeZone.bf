using System;
using Sedulous.Core;
using Sedulous.Navigation;

namespace Sedulous.Engine.Navigation;

/// One live zone: its crowd, its query, and the frame it was baked in.
///
/// A zone bakes in ZONE LOCAL space, so a position or a target crosses this matrix on the way
/// in and out. The frame is RIGID, with the scale dropped, which is what the bake used: a
/// scaled zone entity would otherwise scale the navmesh a second time at runtime.
class NavigationRuntimeZone
{
	public NavigationCrowd Crowd ~ delete _;
	public NavigationMeshQuery Query ~ delete _;

	public Float4x4 World = Float4x4.Identity();
	public Float4x4 InverseWorld = Float4x4.Identity();
	/// The zone box in WORLD space, which is what an agent is placed against.
	public Float3 Center = .(0, 0, 0);
	public Float3 Extents = .(0, 0, 0);
}
