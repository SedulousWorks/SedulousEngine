namespace Sedulous.Core.Tests;

/// An enum field for the generated walker to move. int16 backed, so the test proves the
/// width is taken from the type rather than assumed to be four bytes.
enum SampleKind : int16
{
	None = 0,
	Alpha = 1,
	Beta = 300
}
