namespace Sedulous.RenderGraph;

/// How a pass touches a resource.
///
/// This is what the barrier solver reasons in: each one maps to the resource state the
/// hardware has to be in, and reads and writes are told apart so a hazard between two passes
/// is a fact about the declarations rather than a guess.
enum RGAccessType : uint8
{
	// ---- reads ----
	case ReadTexture;
	case ReadBuffer;
	case ReadDepthStencil;
	/// Sampling a DEPTH texture in a shader. Like a texture read, being sampled rather than
	/// attached, except that the layout has to be the depth read one rather than the shader
	/// read one.
	case SampleDepthStencil;
	case ReadCopySrc;

	// ---- writes ----
	case WriteColorTarget;
	case WriteDepthTarget;
	case WriteStorage;
	case WriteCopyDst;

	// ---- both ----
	case ReadWriteStorage;
	case ReadWriteDepthTarget;
	case ReadWriteColorTarget;
}
