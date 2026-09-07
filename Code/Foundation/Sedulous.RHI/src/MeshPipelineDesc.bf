using System;

namespace Sedulous.RHI;

/// A mesh shader pipeline, which replaces the vertex input and vertex stage with an
/// optional task stage feeding a mesh stage.
///
/// There is no VertexState at all: a mesh shader produces its primitives itself rather
/// than reading a vertex buffer, which is the point of it.
struct MeshPipelineDesc
{
	public IPipelineLayout Layout = null;
	/// The amplification stage. Null runs the mesh shader directly.
	public ProgrammableStage? Task = null;
	/// Required.
	public ProgrammableStage Mesh = .();
	public FragmentState? Fragment = null;
	public Span<ColorTargetState> ColorTargets = default;
	public PrimitiveState Primitive = .();
	public DepthStencilState? DepthStencil = null;
	public MultisampleState Multisample = .();
	public IPipelineCache Cache = null;
	public StringView Label = default;

	public this() {}
}
