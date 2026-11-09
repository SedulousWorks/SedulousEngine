using System;
using System.Collections;
using Sedulous.Core.IO;

namespace Sedulous.Scene.Resource;

/// A prefab loaded for spawning: what a reference to a prefab binds to, built by PrefabFactory
/// from the PrefabDocument record and its scene stream.
///
/// A runtime type of its own: the editor's document stays the authoring record, and nothing at
/// run time holds one. It keeps the payload's bytes (the stream as stored, text or binary), so a
/// spawn reads no disk and parses no envelope; a spawn still assigns fresh ids and records its
/// baseline, so the bytes are what it reads. They are reached only through OpenPayload, so a
/// parsed form can replace them later without changing a caller.
class PrefabResource
{
	private Guid mId;
	private String mName = new .() ~ delete _;
	private List<uint8> mPayload ~ delete _;
	private SceneStreamEncoding mEncoding;

	/// TAKES OWNERSHIP of `payload`.
	public this(Guid id, StringView name, List<uint8> payload)
	{
		mId = id;
		mName.Set(name);
		mPayload = payload;
		let probe = scope PrefabPayloadStream(mPayload);
		mEncoding = SceneStreamFormat.DetectEncoding(probe);
	}

	/// The prefab's content identity.
	public Guid Id => mId;
	/// Its record's name.
	public StringView Name => mName;
	/// Whether the payload is the binary wire or the text a source holds.
	public SceneStreamEncoding Encoding => mEncoding;
	/// The payload's size in bytes: what this prefab holds in memory.
	public int PayloadSize => mPayload.Count;

	/// A read-only stream over the payload, from its start. THE CALLER OWNS the stream; it
	/// borrows the bytes, so it is spent before this resource goes (PrefabPayloadStream).
	public IStream OpenPayload() => new PrefabPayloadStream(mPayload);
}
