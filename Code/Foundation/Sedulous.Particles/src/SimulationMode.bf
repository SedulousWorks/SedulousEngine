namespace Sedulous.Particles;

/// Where a system's update runs.
enum SimulationMode : uint8
{
	case CPU;
	/// A stub for now.
	case GPU;
	/// Resolves to the GPU only when every behaviour supports it AND the system is large
	/// enough to be worth the trip.
	case Auto;
}
