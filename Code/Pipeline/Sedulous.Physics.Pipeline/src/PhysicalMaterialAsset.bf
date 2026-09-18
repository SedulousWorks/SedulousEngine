using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Physics.Pipeline;

/// Authored surface properties.
[Category("Physics")]
[DisplayName("Physical Material")]
[Serializable]
class PhysicalMaterialAsset : Asset
{
	[Range(0.0f, 2.0f, 0.01f)]
	public float Friction = 0.5f;
	[Range(0.0f, 1.0f, 0.01f)]
	public float Restitution = 0.0f;
	[DisplayName("Density (kg/m^3)")]
	[Range(0.0f, 20000.0f, 1.0f)]
	public float Density = 1000.0f;
}
