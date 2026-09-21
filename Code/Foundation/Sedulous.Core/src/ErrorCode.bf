using System;

namespace Sedulous.Core;

/// Why an operation failed.
///
/// Beef already has Result<T, TErr>, so a status is Result<void, ErrorCode> and success is
/// the Ok case rather than an enum member: the enum names failures only.
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
