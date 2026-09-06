namespace Sedulous.Core.Serialization;

/// Which direction a Serialize body is running in.
///
/// One body describes a type's data once and runs either way, so a reader and a writer
/// cannot drift apart the way a separate Load and Save do.
enum SerializeMode
{
	Read,
	Write
}
