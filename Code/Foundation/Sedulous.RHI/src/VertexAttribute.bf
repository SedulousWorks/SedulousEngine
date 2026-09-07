namespace Sedulous.RHI;

/// One vertex attribute within a buffer layout.
struct VertexAttribute
{
	public VertexFormat Format = .Float32;
	/// Bytes from the start of the vertex.
	public uint32 Offset = 0;
	/// The location the shader declares for it.
	public uint32 ShaderLocation = 0;

	public this() {}

	public this(VertexFormat format, uint32 offset, uint32 shaderLocation)
	{
		Format = format; Offset = offset; ShaderLocation = shaderLocation;
	}
}
