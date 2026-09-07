using System;

namespace Sedulous.RHI;

struct RenderPipelineDesc
{
	public IPipelineLayout Layout = null;
	public VertexState Vertex = .();
	/// Null for a depth only pass, which writes no colour and needs no fragment stage.
	public FragmentState? Fragment = null;
	public PrimitiveState Primitive = .();
	/// Null when the pipeline neither tests nor writes depth.
	public DepthStencilState? DepthStencil = null;
	public MultisampleState Multisample = .();
	/// Optional. Speeds up creation and is otherwise invisible.
	public IPipelineCache Cache = null;
	public StringView Label = default;

	public this() {}
}
