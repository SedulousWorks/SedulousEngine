using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// Makes a type serializable WITHOUT owning it.
///
/// The attribute is applied to an extension rather than to the declaration, so a type from
/// another library, or from corlib, can be given a Serialize body and the ISerializable
/// interface by the project that wants to store it. The generated walker reads the fields
/// off the merged type, so it sees the ones the extension does not declare.
[Serializable]
extension ForeignType
{
}
