using Sedulous.RHI;

namespace Sedulous.Render;

/// How a render target's resource state is handled.
///
/// The default is the host managed back buffer, which the presenting code owns. An OFFSCREEN
/// target instead gives its texture, so the graph can barrier it, along with the state it is
/// in now and the state to leave it in: shader read to sample it next, copy source to blit it.
struct TargetState
{
	public ITexture Texture = null;
	public ResourceState CurrentState = .RenderTarget;
	public ResourceState FinalState = .RenderTarget;

	public this() {}

	public this(ITexture texture, ResourceState currentState, ResourceState finalState)
	{
		Texture = texture;
		CurrentState = currentState;
		FinalState = finalState;
	}
}
