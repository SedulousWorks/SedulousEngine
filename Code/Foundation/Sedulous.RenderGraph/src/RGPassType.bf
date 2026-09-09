namespace Sedulous.RenderGraph;

/// What kind of work a pass does, which decides the queue it can run on and the encoder it
/// is given.
enum RGPassType : uint8
{
	case Render;
	case Compute;
	case Copy;
}
