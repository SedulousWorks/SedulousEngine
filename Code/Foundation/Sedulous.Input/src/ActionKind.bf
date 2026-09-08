namespace Sedulous.Input;

/// What an action PRODUCES.
///
/// Declared, never inferred. Asking a button for a vector is a caller's mistake that the
/// editor's validation surfaces, rather than a silent zero: the archived engine collapsed
/// everything to an {X, Y} pair and lost the distinction, so a button and a stick read the
/// same and nothing could tell you which you had meant.
enum ActionKind : uint8
{
	Button,
	Axis1D,
	Axis2D
}
