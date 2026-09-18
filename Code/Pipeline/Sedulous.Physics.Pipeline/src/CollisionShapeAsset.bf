using Sedulous.Core;
using System;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Physics.Pipeline;

/// Which mesh to cook a collision shape from, and how.
///
/// Sourced by identity rather than by path, so the file name a plain asset carries goes unused.
[Category("Physics")]
[Serializable]
class CollisionShapeAsset : Asset
{
	/// The static mesh asset this is cooked from.
	public Guid SourceMesh = .Empty;
	[DisplayName("Cook Mode")]
	public CollisionCookKind Cook = .ConvexHull;
	/// How much slack the convex simplification is allowed.
	[Range(0.0f, 0.1f, 0.0001f)]
	[VisibleWhen("Cook=0")] // convex hull only
	public float HullTolerance = 1.0e-3f;
}
