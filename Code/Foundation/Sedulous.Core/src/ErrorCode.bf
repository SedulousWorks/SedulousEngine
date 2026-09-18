using System;

namespace Sedulous.Core;

/// Why an operation failed.
///
/// Raptor pairs this enum with a Status class and a Result of its own, and gives the enum
/// an Ok member so Status can hold it. Beef already has Result<T, TErr>, so Status is just
/// Result<void, ErrorCode> here and success is the Ok case rather than an enum member.
[Scriptable(.AllPublic)]
enum ErrorCode
{
	Unknown,
	InvalidArgument,
	OutOfRange,
	OutOfMemory,
	NotFound,
	NotSupported,
	AlreadyExists,
	Internal
}
