namespace Sedulous.UI;

/// How a flex line distributes its items along the MAIN axis.
enum Justify
{
	case Start;
	case End;
	case Center;
	/// The free space is split between the items, the first and last flush to the edges.
	case SpaceBetween;
	/// Every item gets an equal margin, so the end gaps are HALF the gaps between items.
	case SpaceAround;
	/// Every gap is equal, the end ones included.
	case SpaceEvenly;
}
