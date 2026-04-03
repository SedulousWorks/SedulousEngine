namespace Sedulous.RHI;

/// An immutable, recorded command buffer ready for submission.
/// Created by calling ICommandEncoder.Finish().
/// Owned by its command pool — destroyed when the pool is reset or destroyed.
interface ICommandBuffer
{
}
