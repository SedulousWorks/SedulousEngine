namespace Sedulous.RHI;

/// An immutable, pre recorded run of draws, replayable into any pass whose attachment
/// signature matches the descriptor it was recorded against.
///
/// OWNED BY THE COMMAND POOL that produced it, and valid only until that pool is reset.
interface IRenderBundle
{
}
