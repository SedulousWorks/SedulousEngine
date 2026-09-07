using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullQuerySet : IQuerySet
{
	private QueryType mType = .Timestamp;
	private uint32 mCount = 0;

	public QueryType Type => mType;
	public uint32 Count => mCount;

	public void Initialize(QuerySetDesc desc)
	{
		mType = desc.Type;
		mCount = desc.Count;
	}
}
