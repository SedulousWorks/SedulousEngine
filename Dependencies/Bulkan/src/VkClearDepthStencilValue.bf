namespace Bulkan;

extension VkClearDepthStencilValue
{
	public this(float depth, uint32 stencil) : this()
	{
		this.depth = depth;
        this.stencil = stencil;
	}
}
