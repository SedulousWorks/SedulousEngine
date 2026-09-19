namespace Sedulous.RHI;

struct DepthStencilState
{
	public TextureFormat Format = .Undefined;
	public bool DepthTestEnabled = true;
	public bool DepthWriteEnabled = true;
	/// The engine's depth convention: see Depth.
	public CompareFunction DepthCompare = Depth.Nearer;

	public bool StencilEnabled = false;
	public uint8 StencilReadMask = 0xFF;
	public uint8 StencilWriteMask = 0xFF;
	public StencilFaceState StencilFront = .();
	public StencilFaceState StencilBack = .();

	/// A constant offset in depth units, for pushing coplanar geometry apart.
	public int32 DepthBias = 0;
	/// Scaled by the polygon's depth slope, which is what makes the offset hold at grazing
	/// angles where a constant bias does not.
	public float DepthBiasSlopeScale = 0.0f;
	public float DepthBiasClamp = 0.0f;

	public this() {}
}
