namespace Sedulous.RHI;

using System;

// =============================================================================
// Mesh Shader Extension
// =============================================================================
// Provides mesh shader and task (amplification) shader support.
// Vulkan: VK_EXT_mesh_shader. DX12: Mesh Shader Pipeline.
//
// Query support: `if (let meshExt = device.GetMeshShaderExt())`
// A backend that does not support mesh shaders (e.g. WebGPU) returns null.

/// Describes a mesh shader pipeline.
struct MeshPipelineDesc
{
	public IPipelineLayout Layout;
	/// Optional task (amplification) shader.
	public ProgrammableStage? Task;
	/// Required mesh shader.
	public ProgrammableStage Mesh;
	/// Optional fragment shader.
	public ProgrammableStage? Fragment;
	public Span<ColorTargetState> ColorTargets;
	public PrimitiveState Primitive = .();
	public DepthStencilState? DepthStencil;
	public MultisampleState Multisample = .();
	public IPipelineCache Cache;
	public StringView Label;
}

/// Extension interface for mesh shader support.
interface IMeshShaderExt
{
	/// Creates a mesh shader pipeline (task + mesh + fragment).
	Result<IMeshPipeline> CreateMeshPipeline(MeshPipelineDesc desc);

	/// Destroys a mesh pipeline.
	void DestroyMeshPipeline(ref IMeshPipeline pipeline);
}

/// A compiled mesh shader pipeline.
interface IMeshPipeline
{
	IPipelineLayout Layout { get; }
}

/// Extension to IRenderPassEncoder for mesh shader draw commands.
/// Check support by casting: `if (let meshPass = renderPassEncoder as IMeshShaderPassExt)`
interface IMeshShaderPassExt
{
	/// Binds a mesh shader pipeline for subsequent DrawMeshTasks calls.
	void SetMeshPipeline(IMeshPipeline pipeline);

	/// Dispatches mesh shader work groups.
	void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1, uint32 groupCountZ = 1);

	/// Dispatches mesh shader work groups with indirect parameters from a buffer.
	void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset,
		uint32 drawCount = 1, uint32 stride = 0);

	/// Dispatches mesh shader work groups with indirect parameters and
	/// draw count read from a separate buffer.
	void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset,
		IBuffer countBuffer, uint64 countOffset,
		uint32 maxDrawCount, uint32 stride);
}
