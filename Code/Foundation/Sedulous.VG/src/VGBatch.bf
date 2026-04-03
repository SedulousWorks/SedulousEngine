using System;
using System.Collections;

namespace Sedulous.VG;

/// Contains batched vector graphics geometry and draw commands for rendering.
/// This is the output of VGContext that an external renderer consumes.
public class VGBatch
{
	/// Vertex data for all geometry
	public List<VGVertex> Vertices = new .() ~ delete _;
	/// Index data for all geometry (uint32 for complex paths)
	public List<uint32> Indices = new .() ~ delete _;
	/// Draw commands (batched by state)
	public List<VGCommand> Commands = new .() ~ delete _;

	/// Get vertex data as a span for GPU upload
	public Span<VGVertex> GetVertexData()
	{
		return Vertices;
	}

	/// Get index data as a span for GPU upload
	public Span<uint32> GetIndexData()
	{
		return Indices;
	}

	/// Number of draw commands
	public int CommandCount => Commands.Count;

	/// Get a specific draw command
	public VGCommand GetCommand(int index)
	{
		return Commands[index];
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
