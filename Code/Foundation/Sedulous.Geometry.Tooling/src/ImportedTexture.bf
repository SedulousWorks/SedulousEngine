namespace Sedulous.Geometry.Tooling;

using System;
using Sedulous.Images;

/// Texture data extracted from a model file.
/// Contains the decoded pixel data and metadata.
/// No dependency on the renderer - the application uploads to GPU.
class ImportedTexture
{
	/// Texture name from the source model (file extension stripped).
	public String Name = new .() ~ delete _;
	/// Decoded pixel data. Owned by this instance.
	public Image PixelData ~ delete _;
}
