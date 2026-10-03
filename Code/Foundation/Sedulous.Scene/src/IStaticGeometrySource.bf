using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Scene;

/// The scene's fixed, solid surfaces as one system knows them: the world space triangles of
/// what it owns that does not move and that things stand on or are blocked by (physics: its
/// static, solid bodies; terrain: its surface). Navigation bakes from every system that has
/// some, so what moves (agents, dynamic bodies, characters) never becomes level geometry.
interface IStaticGeometrySource
{
	/// Appends the triangles touching `bounds`, three positions each, counter clockwise seen
	/// from outside; a triangle reaching past `bounds` comes whole. `detail` is the finest
	/// spacing worth producing: a sampled surface need not be finer.
	void CollectStaticGeometry(Scene scene, AABB bounds, float detail, List<Float3> outTriangles);
}
