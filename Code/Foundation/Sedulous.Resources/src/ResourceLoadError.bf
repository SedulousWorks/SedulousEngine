namespace Sedulous.Resources;

/// Error codes for resource loading.
enum ResourceLoadError
{
	/// Resource was not found.
	NotFound,
	/// No resource manager registered for this type.
	ManagerNotFound,
	/// Resource format is invalid.
	InvalidFormat,
	/// Failed to read resource data.
	ReadError,
	/// Operation not supported by this manager.
	NotSupported,
	/// Unknown error.
	Unknown
}
