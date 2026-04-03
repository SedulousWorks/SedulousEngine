using System;
using System.Collections;

namespace Sedulous.Drawing;

/// Contains batched geometry and draw commands for rendering.
/// This is the output of DrawContext that an external renderer consumes.
public class DrawBatch
{
	/// Vertex data for all geometry
	public List<DrawVertex> Vertices = new .() ~ delete _;
	/// Index data for all geometry
	public List<uint16> Indices = new .() ~ delete _;
	/// Draw commands (batched by state)
	public List<DrawCommand> Commands = new .() ~ delete _;
	/// Textures referenced by commands (by TextureIndex)
	/// These are not owned by DrawBatch - caller must manage texture lifetime
	public List<IImageData> Textures = new .() ~ delete _;

	/// Get vertex data as a span for GPU upload
	public Span<DrawVertex> GetVertexData()
	{
		return Vertices;
	}

	/// Get index data as a span for GPU upload
	public Span<uint16> GetIndexData()
	{
		return Indices;
	}

	/// Number of draw commands
	public int CommandCount => Commands.Count;

	/// Get a specific draw command
	public DrawCommand GetCommand(int index)
	{
		return Commands[index];
	}

	/// Get the texture for a command
	public IImageData GetTextureForCommand(int index)
	{
		let cmd = Commands[index];
		if (cmd.TextureIndex >= 0 && cmd.TextureIndex < Textures.Count)
			return Textures[cmd.TextureIndex];
		return null;
	}


	/// Total vertex count
	public int VertexCount => Vertices.Count;

	/// Total index count
	public int IndexCount => Indices.Count;

	/// Clear all data for reuse
	public void Clear()
	{
		Vertices.Clear();
		Indices.Clear();
		Commands.Clear();
		Textures.Clear();
	}

	/// Reserve capacity for expected geometry
	public void Reserve(int vertexCount, int indexCount, int commandCount)
	{
		if (vertexCount > Vertices.Capacity)
			Vertices.Reserve(vertexCount);
		if (indexCount > Indices.Capacity)
			Indices.Reserve(indexCount);
		if (commandCount > Commands.Capacity)
			Commands.Reserve(commandCount);
	}

	/// Check if batch has any content
	public bool IsEmpty => Vertices.Count == 0 || Indices.Count == 0 || Commands.Count == 0;
}
