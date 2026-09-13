using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Physics.Pipeline;

/// Authored surface properties.
[Serializable]
class PhysicalMaterialAsset : Asset
{
	public float Friction = 0.5f;
	public float Restitution = 0.0f;
	public float Density = 1000.0f;
}
