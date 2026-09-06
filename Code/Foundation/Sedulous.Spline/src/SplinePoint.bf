using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Spline;

/// One authored point: a position and its two handles.
///
/// Handles are RELATIVE to the position and are STORED rather than derived at evaluation
/// time. UpdateAutoHandles resolves the Auto ones after an edit, which is what makes
/// evaluation and serialization deterministic instead of dependent on when they last ran.
struct SplinePoint
{
	public Float3 Position;
	/// Toward the previous point.
	public Float3 InHandle;
	/// Toward the next point.
	public Float3 OutHandle;
	public SplineHandleMode Mode = .Auto;

	public this()
	{
		Position = .Zero; InHandle = .Zero; OutHandle = .Zero; Mode = .Auto;
	}

	public this(Float3 position, SplineHandleMode mode = .Auto)
	{
		Position = position; InHandle = .Zero; OutHandle = .Zero; Mode = mode;
	}

	/// Describes itself, so a type holding a point picks this up through the generated
	/// body's self serializing escape hatch rather than needing Core to know what a spline
	/// point is.
	public void Serialize(ISerializer ar) mut
	{
		ar.Key("position");
		Sedulous.Core.Serialization.Serialize(ar, ref Position);
		ar.Key("in");
		Sedulous.Core.Serialization.Serialize(ar, ref InHandle);
		ar.Key("out");
		Sedulous.Core.Serialization.Serialize(ar, ref OutHandle);
		ar.Key("mode");
		SerializeEnum(ar, ref Mode);
	}
}
