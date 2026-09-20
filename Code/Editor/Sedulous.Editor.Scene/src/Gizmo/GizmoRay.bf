using Sedulous.Core;

namespace Sedulous.Editor.Scene;

struct GizmoRay
{
	public Float3 Origin = .Zero;
	public Float3 Direction = .(0.0f, 0.0f, -1.0f);

	public this() {}
	public this(Float3 origin, Float3 direction)
	{
		Origin = origin;
		Direction = direction;
	}
}
