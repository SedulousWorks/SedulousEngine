using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Content;

/// The database surface a consumer sees, so a backend can be swapped underneath it.
interface IContentDatabase
{
	Group RootGroup { get; }

	Instance GetInstance(Guid id);
	Instance GetInstanceByPath(StringView path);

	/// Reads an instance's primary object by identity. THE CALLER OWNS the result.
	ISerializable ReadObject(Guid id);
}
