namespace Sedulous.RHI;

/// How texture data sits inside a buffer, for an upload or a readback.
///
/// BytesPerRow is the STRIDE, not the used width: backends require it aligned, commonly to
/// 256 bytes, so it is usually larger than the row actually occupies. Zero means tightly
/// packed and lets the backend derive it.
struct TextureDataLayout
{
	public uint64 Offset = 0;
	public uint32 BytesPerRow = 0;
	/// Rows between the start of consecutive depth slices or array layers. Zero means the
	/// image height.
	public uint32 RowsPerImage = 0;

	public this() {}
}
