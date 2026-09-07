using Sedulous.RHI;

namespace Sedulous.RHI.Null;

class NullAccelStruct : IAccelStruct
{
	private AccelStructType mType = .BottomLevel;

	public AccelStructType Type => mType;

	/// Zero: there is no device memory to address. A caller building a top level structure
	/// from this would be pointing at nothing, which is correct for a backend that traces
	/// no rays.
	public uint64 DeviceAddress => 0;

	public void Initialize(AccelStructDesc desc) => mType = desc.Type;
}
