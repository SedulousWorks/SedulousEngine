namespace Sedulous.RenderGraph;

/// How bad a validation finding is.
///
/// An ERROR is a graph that will draw the wrong thing; a WARNING is one that will draw the
/// right thing wastefully.
enum ValidationSeverity
{
	case Warning;
	case Error;
}
