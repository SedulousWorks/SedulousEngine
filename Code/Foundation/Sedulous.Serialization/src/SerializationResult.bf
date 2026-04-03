namespace Sedulous.Serialization;

/// Result codes for serialization operations.
enum SerializationResult
{
	/// Operation completed successfully.
	Ok,

	/// A required field was not found during deserialization.
	FieldNotFound,

	/// The serialized data type doesn't match the expected type.
	TypeMismatch,

	/// The serialized data is malformed or corrupt.
	InvalidData,

	/// An object reference could not be resolved.
	InvalidReference,

	/// The serializer is in the wrong mode for this operation.
	WrongMode,

	/// A null value was encountered where one is not allowed.
	NullValue,

	/// An array had an unexpected number of elements.
	ArraySizeMismatch,

	/// The serialized version is not supported.
	UnsupportedVersion,

	/// A general I/O error occurred.
	IOError,

	/// An object of an unknown type was encountered.
	UnknownType,

	/// Maximum nesting depth exceeded.
	NestingTooDeep,

	/// Duplicate key or name encountered.
	DuplicateKey,
}
