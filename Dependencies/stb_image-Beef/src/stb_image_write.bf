using System;
using System.Interop;
namespace stb_image;

/* stb_image_write - v1.16 - public domain image writer - http://nothings.org/stb
   Declarations for the writer half of the stb_image native library.

   Each writer takes the pixel data as `comp` interleaved 8-bit channels per pixel,
   `w * h` of them, with row 0 at the TOP. stride_bytes is the distance between rows,
   or 0 to mean tightly packed.

   Returns non-zero on success. */

static
{
	/// stride_in_bytes is the distance between rows; 0 means tightly packed.
	[CLink] public static extern int32 stbi_write_png(char8* filename, int32 w, int32 h, int32 comp, void* data, int32 stride_in_bytes);
	[CLink] public static extern int32 stbi_write_bmp(char8* filename, int32 w, int32 h, int32 comp, void* data);
	[CLink] public static extern int32 stbi_write_tga(char8* filename, int32 w, int32 h, int32 comp, void* data);
	/// `data` is float, not bytes: HDR stores linear radiance.
	[CLink] public static extern int32 stbi_write_hdr(char8* filename, int32 w, int32 h, int32 comp, float* data);
	/// quality runs 1 to 100; higher is better and larger.
	[CLink] public static extern int32 stbi_write_jpg(char8* filename, int32 w, int32 h, int32 comp, void* data, int32 quality);

	/// Writes through a callback instead of to a path, for an archive or a memory buffer.
	public function void stbi_write_func(void* context, void* data, int32 size);

	[CLink] public static extern int32 stbi_write_png_to_func(stbi_write_func func, void* context, int32 w, int32 h, int32 comp, void* data, int32 stride_in_bytes);
	[CLink] public static extern int32 stbi_write_bmp_to_func(stbi_write_func func, void* context, int32 w, int32 h, int32 comp, void* data);
	[CLink] public static extern int32 stbi_write_tga_to_func(stbi_write_func func, void* context, int32 w, int32 h, int32 comp, void* data);
	[CLink] public static extern int32 stbi_write_hdr_to_func(stbi_write_func func, void* context, int32 w, int32 h, int32 comp, float* data);
	[CLink] public static extern int32 stbi_write_jpg_to_func(stbi_write_func func, void* context, int32 w, int32 h, int32 comp, void* data, int32 quality);

	/// Deflate level for PNG, default 8.
	[CLink] public static extern int32 stbi_write_png_compression_level;
	/// Forces one PNG row filter rather than choosing per row, or -1 to choose. Default -1.
	[CLink] public static extern int32 stbi_write_force_png_filter;
	/// Non-zero run length encodes TGA, default 1.
	[CLink] public static extern int32 stbi_write_tga_with_rle;

	/// Non-zero writes images bottom-up, which is the origin OpenGL reads textures from.
	/// Applies to every subsequent write until it is set back.
	[CLink] public static extern void stbi_flip_vertically_on_write(int32 flip);
}
