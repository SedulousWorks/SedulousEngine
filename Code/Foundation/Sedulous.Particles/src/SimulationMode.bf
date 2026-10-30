using System;

namespace Sedulous.Particles;

/// Where a system's update runs.
[Reflect(.StaticFields)] // its cases, by name, for a row to offer
enum SimulationMode : uint8
{
	case CPU;
	/// A stub for now.
	case GPU;
	/// Resolves to the GPU only when every behaviour supports it AND the system is large
	/// enough to be worth the trip.
	case Auto;
}
