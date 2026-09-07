namespace Sedulous.Model.FBX;

/// Where each attribute sits in a vertex, and which of them the source mesh actually has.
///
/// Passed around rather than recomputed, because building a vertex needs all of it and the
/// offsets are decided once per mesh.
struct VertexLayout
{
	public int32 Stride;
	public int32 PositionOffset;
	public int32 NormalOffset;
	public int32 TexCoordOffset;
	public int32 ColorOffset;
	public int32 TangentOffset;
	public int32 JointsOffset;
	public int32 WeightsOffset;

	/// The slots exist whatever the source has; these say whether there is anything to put
	/// in them, or whether the neutral default applies.
	public bool IsSkinned;
	public bool HasUv;
	public bool HasTangent;
	public bool HasColor;

	public this()
	{
		Stride = 0; PositionOffset = 0; NormalOffset = 0; TexCoordOffset = 0;
		ColorOffset = 0; TangentOffset = 0; JointsOffset = 0; WeightsOffset = 0;
		IsSkinned = false; HasUv = false; HasTangent = false; HasColor = false;
	}
}
