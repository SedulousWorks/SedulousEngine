using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Xml.Serialization;

/// The XML format, as a factory a store can be handed.
static
{
	/// A factory that makes XML serializers. THE CALLER OWNS the delegate, and owns each
	/// context the delegate returns.
	///
	/// This is how a content database gets an XML format without importing one: it is
	/// handed the factory and never names the backend.
	public static SerializerFactory XmlSerializerFactory()
	{
		return new (stream, mode) => new XmlSerializerContext(stream, mode);
	}
}
