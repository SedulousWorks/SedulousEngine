namespace Sedulous.RHI;

/// A ray tracing acceleration structure, top or bottom level.
interface IAccelStruct
{
	AccelStructType Type { get; }

	/// The address a shader or a top level build refers to it by. Ray tracing structures
	/// reference each other by ADDRESS rather than by handle, which is why this is on the
	/// interface rather than left to the backend.
	uint64 DeviceAddress { get; }
}
