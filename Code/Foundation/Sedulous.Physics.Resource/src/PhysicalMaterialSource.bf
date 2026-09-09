using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Physics.Resource;

/// The cooked record for a surface's properties, which a rigid body references instead of
/// authoring them inline on every collider that shares them.
[Serializable]
class PhysicalMaterialSource
{
	public float Friction = 0.5f;
	public float Restitution = 0.0f;
	/// Kilograms per cubic metre.
	public float Density = 1000.0f;
}
