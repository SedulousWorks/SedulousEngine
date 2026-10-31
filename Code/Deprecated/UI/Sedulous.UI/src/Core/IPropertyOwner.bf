namespace Sedulous.UI;

/// Something that owns Property values and invalidates itself when one changes.
///
/// Kept separate from View rather than folded into it: this is what breaks the cycle between
/// Property and View, and it lets a non View object own properties too.
interface IPropertyOwner
{
	void OnPropertyChanged(InvalidationKind kind);
}
