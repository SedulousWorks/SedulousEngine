namespace Sedulous.Resources;

using System;
using System.IO;
using System.Collections;

/// Maps resource GUIDs to URIs (scheme://locator) and vice versa.
///
/// An index is identity-only - it doesn't know how to read bytes. The byte layer
/// is `Sedulous.VFS.IMount`; the `ResourceSystem` glues them together by parsing
/// the URI scheme, looking up the matching mount, and asking that mount to open
/// the locator.
///
/// Multiple indices stack in the `ResourceSystem` (queried in registration order),
/// allowing a "builtin" index, a per-project index, package indices, etc., to
/// coexist without one overriding the others' GUIDs.
interface IResourceIndex
{
	/// Looks up the URI registered for `id`. Returns true if found; `outUri` is
	/// filled with a scheme-prefixed URI like "project://textures/foo.tex".
	bool TryResolveUri(Guid id, String outUri);

	/// Looks up the GUID registered for a URI. Returns true if found.
	bool TryResolveId(StringView uri, out Guid id);

	/// Registers a GUID -> URI mapping, replacing any prior mapping for that GUID.
	void Register(Guid id, StringView uri);

	/// Removes the mapping for `id`. No-op if missing.
	void Unregister(Guid id);

	/// Number of entries.
	int Count { get; }

	/// Appends every (id, uri) pair to `outEntries`.
	/// The yielded `StringView` references the index's internal string and is only
	/// valid until the next mutation.
	void GetEntries(List<(Guid id, StringView uri)> outEntries);

	/// Writes the index in a stable format. The caller owns the stream.
	Result<void> SerializeTo(Stream stream);

	/// Reads entries from a serialized stream, appending to the existing set.
	/// Caller owns the stream.
	Result<void> DeserializeFrom(Stream stream);
}
