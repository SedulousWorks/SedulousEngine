namespace Sedulous.Editor.Generic;

enum AssetFormFieldKind : uint8
{
	/// bool, ints, floats; see the scalar kind.
	case Scalar;
	/// A String.
	case Text;
	/// A Guid: the canonical string plus an untyped asset picker in the UI.
	case Guid;
	/// Opaque bytes, shown read-only and replayed verbatim.
	case Blob;
	/// BeginArray's count: hidden from the UI, replayed verbatim.
	case ArrayCount;
}
