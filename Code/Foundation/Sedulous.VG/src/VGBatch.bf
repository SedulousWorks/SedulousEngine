using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.VG;

/// The geometry and draw commands a context produces, for a renderer to consume.
///
/// The fields are public because the tessellation and clip code writes straight into them:
/// this is a buffer being filled, not an object with an invariant to protect.
class VGBatch
{
	public List<VGVertex> Vertices = new .() ~ delete _;
	public List<uint32> Indices = new .() ~ delete _;
	public List<VGCommand> Commands = new .() ~ delete _;

	/// The textures commands refer to by index. NOT OWNED: the context manages their
	/// lifetime. By convention index zero is a one by one white texture, which is what
	/// lets a solid colour draw share the textured pipeline.
	public List<ImageData> Textures = new .() ~ delete _;

	/// Sources whose renderer side GPU cache entries must be DROPPED before this batch's
	/// textures are considered, such as an evicted gradient ramp.
	///
	/// Identity keys only. The renderer compares references and never dereferences them,
	/// because by the time it sees this list the object may already be gone.
	public List<ImageData> EvictedTextures = new .() ~ delete _;

	/// What a distance field command's shader needs for its screen space antialiasing: the
	/// spread in texels, and the atlas it was baked against.
	public float DistanceFieldPixelRange = 4.0f;
	public float DistanceFieldAtlasWidth = 512.0f;
	public float DistanceFieldAtlasHeight = 512.0f;

	public Span<VGVertex> GetVertexData() => Vertices;
	public Span<uint32> GetIndexData() => Indices;

	public int CommandCount => Commands.Count;
	public int VertexCount => Vertices.Count;
	public int IndexCount => Indices.Count;

	public VGCommand GetCommand(int index) => Commands[index];

	/// The texture a command draws with, or null when it has none or names one that is not
	/// there.
	public ImageData GetTextureForCommand(int index)
	{
		let command = Commands[index];
		if ((command.TextureIndex >= 0) && (command.TextureIndex < Textures.Count))
			return Textures[command.TextureIndex];
		return null;
	}

	/// Empties everything for reuse, the TEXTURE LIST INCLUDED. The caller re-adds what it
	/// needs, starting with the white fallback at index zero.
	public void Clear()
	{
		Vertices.Clear();
		Indices.Clear();
		Commands.Clear();
		Textures.Clear();
		EvictedTextures.Clear();
	}

	public void Reserve(int vertexCount, int indexCount, int commandCount)
	{
		Vertices.Reserve(vertexCount);
		Indices.Reserve(indexCount);
		Commands.Reserve(commandCount);
	}

	/// Nothing to draw. All three must be present: geometry with no command is never
	/// submitted, and a command with no geometry draws nothing.
	public bool IsEmpty => Vertices.IsEmpty || Indices.IsEmpty || Commands.IsEmpty;
}
