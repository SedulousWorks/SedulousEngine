using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Spline;

using Sedulous.Core;

namespace Sedulous.Engine.Spline;

/// An authorable curve as scene DATA, and nothing more.
///
/// Data only on purpose: there is no tick and no subsystem. Consumers evaluate it, path
/// follow first among them, and the editor's spline tool authors it. The manager exists so
/// it serializes and rides scene composition.
[SerializableComponent("spline")]
[DisplayName("Spline")]
[Category("Utility")]
[Scriptable]
struct SplineComponent : ISerializable
{
	/// BORROWED from the manager, which creates one per component and frees it again. A
	/// component is a struct in a packed pool, so it cannot own heap data itself: the pool
	/// copies it on every swap remove.
	public SplineCurve Curve = null;

	public this() {}

	// The inspector's rows (points are authored in the viewport by the spline tool): the
	// loop flag, through the curve so its arc-length table follows, and the point count.
	[InspectorProperty("closed", "SetClosed")]
	public bool IsClosed() => Curve.Closed;
	public void SetClosed(bool closed)
	{
		if (Curve.Closed != closed)
		{
			Curve.Closed = closed;
			Curve.RebuildArcLength();
		}
	}
	[InspectorProperty("pointCount")]
	public uint32 PointCount() => (uint32)Curve.Points.Count;

	/// What a spline added with no points starts as: a short segment along the entity's
	/// local X, so the viewport tool has points to grab and the gizmo shows a curve at once.
	/// Also the runtime's answer for a script that adds the component bare.
	public static void SeedDefault(SplineCurve curve)
	{
		curve.Points.Add(SplinePoint(.(-1.0f, 0.0f, 0.0f)));
		curve.Points.Add(SplinePoint(.(1.0f, 0.0f, 0.0f)));
		curve.UpdateAutoHandles();
		curve.RebuildArcLength();
	}

	public void Serialize(ISerializer ar) mut
	{
		// Written by hand rather than through SerializeList: a point describes ITSELF, and the
		// list helper routes every element through the value dispatcher, which has no case
		// for a self serializing struct.
		ar.Key("points");
		uint32 count = (uint32)Curve.Points.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			Curve.Points.Clear();
			Curve.Points.Reserve((int)count);
			for (uint32 i < count)
			{
				var point = SplinePoint();
				point.Serialize(ar);
				Curve.Points.Add(point);
			}
		}
		else
		{
			for (int i < Curve.Points.Count)
			{
				var point = Curve.Points[i];
				point.Serialize(ar);
			}
		}
		ar.EndArray();

		SerializeValue(ar, "closed", ref Curve.Closed);

		// The stored handles are authoritative, so only the DERIVED caches rebuild.
		if (ar.Mode == .Read)
			Curve.RebuildArcLength();
	}
}
