namespace Sedulous.VG.Renderer;

/// The fragment shader and role families that need a pipeline per blend mode.
///
/// The stencil WRITE pipelines are absent because they are colour masked: they write no
/// colour, so the blend state does not reach them.
enum PipelineKind : uint8
{
	case Default;
	case DistanceField;
	case GradRadial;
	case GradConic;
	case Cover;
	case CoverRadial;
	case CoverConic;
	case BoxShadow;
	/// Analytic boxes, with their own vertex layout and shaders.
	case Box;
	/// Layer composites, which sample a premultiplied target. Keep last: Count follows it.
	case Layer;

	public const int Count = (int)Layer + 1;
}
