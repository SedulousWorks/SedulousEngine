namespace Sedulous.Materials;

/// The predefined vertex layouts, which are the byte formats meshes and sprites supply.
enum VertexLayoutType : uint8
{
	/// Procedural: no vertex input at all.
	case None;
	/// float3. A skybox or a shadow depth pass.
	case PositionOnly;
	/// float3 + float2 + float4. Sprites and particles.
	case PositionUVColor;
	/// float3 + float3 + float2.
	case MeshNoTangent;
	/// The above plus a packed colour and a tangent.
	case Mesh;
	/// The static stream, with the joints and weights arriving in a SEPARATE buffer.
	case SkinnedMesh;
	case Custom;
}
