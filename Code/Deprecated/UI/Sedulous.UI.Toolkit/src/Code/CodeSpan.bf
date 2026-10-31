namespace Sedulous.UI.Toolkit;

/// A range between two positions.
///
/// A span may run BACKWARDS, because a selection dragged leftwards has its anchor after its
/// cursor and the document cares which end the user started from. Anything that operates on the
/// range normalises first.
struct CodeSpan
{
	public CodePosition Begin = .();
	public CodePosition End = .();

	public this() {}

	public this(CodePosition begin, CodePosition end)
	{
		Begin = begin;
		End = end;
	}

	public bool IsEmpty => Begin == End;

	public CodeSpan Normalized => (Begin <= End) ? this : .(End, Begin);
}
