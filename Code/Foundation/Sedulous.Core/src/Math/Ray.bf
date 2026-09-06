using System;

namespace Sedulous.Core;

/// A position and a direction.
[CRepr]
struct Ray
{
	public Float3 position;
	public Float3 direction;

	public this() { position = default; direction = default; }
	public this(Float3 position, Float3 direction)
	{
		this.position = position; this.direction = direction;
	}

	public Ray Interpolate(Ray target, float t) =>
		.(Lerp(position, target.position, t), Lerp(direction, target.direction, t));
}
