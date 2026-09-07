namespace Sedulous.RHI;

/// Which level of the ray tracing hierarchy a structure holds. A bottom level holds
/// geometry; a top level holds instances of bottom levels.
enum AccelStructType : uint32
{
	TopLevel,
	BottomLevel
}
