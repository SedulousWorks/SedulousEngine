namespace Sedulous.UI;

/// One ancestor step: the compound an ancestor must match, and whether it has to be the
/// DIRECT parent of the view matched by the step before it, which is what `>` means against a
/// plain descendant space.
class SelectorAncestor
{
	/// OWNED.
	public SelectorCompound Compound ~ delete _;
	public bool DirectParent = false;

	/// OWNERSHIP of the compound transfers.
	public this(SelectorCompound compound, bool directParent)
	{
		Compound = compound;
		DirectParent = directParent;
	}
}
