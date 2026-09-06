using Sedulous.Core.IO;

namespace Sedulous.Core.Serialization;

/// Makes a serializer for a stream and a direction.
///
/// This is the seam that keeps a store from naming a format. A content database is handed
/// one of these and never imports a concrete serializer, so which format is on disk is the
/// caller's decision rather than the store's.
typealias SerializerFactory = delegate SerializerContext(IStream stream, SerializeMode mode);
