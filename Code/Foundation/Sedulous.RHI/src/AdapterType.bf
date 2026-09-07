namespace Sedulous.RHI;

/// What kind of device an adapter stands for. Used to rank adapters when nothing else
/// distinguishes them, which is why the order here is the preference order.
enum AdapterType : uint32
{
	DiscreteGpu,
	IntegratedGpu,
	Cpu,
	Unknown
}
