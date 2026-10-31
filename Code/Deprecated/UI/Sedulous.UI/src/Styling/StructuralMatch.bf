namespace Sedulous.UI;

/// The structural pseudo classes: where a view sits among its siblings, and whether it has
/// any children of its own.
enum StructuralMatch : uint8
{
	None = 0,
	FirstChild = 1,
	LastChild = 2,
	Empty = 4
}
