using System;

namespace Sedulous.Core;

/// A Position and a Direction.
[CRepr]
struct Ray
{
	public Float3 Position;
	public Float3 Direction;

	public this() { Position = default; Direction = default; }
	public this(Float3 position, Float3 direction)
	{
		this.Position = position; this.Direction = direction;
	}

	public Ray Interpolate(Ray target, float t) =>
		.(Lerp(Position, target.Position, t), Lerp(Direction, target.Direction, t));
}
