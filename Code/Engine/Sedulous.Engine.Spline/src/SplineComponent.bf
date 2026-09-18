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
