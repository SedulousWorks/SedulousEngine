namespace Sedulous.RHI;

/// A block of GPU queries of one kind, indexed by slot.
interface IQuerySet
{
	QueryType Type { get; }
	uint32 Count { get; }
}
