using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Runtime.Client;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// What every asset page shares, so each of the twenty
// libraries does not write its own: the services a page asks of the editor when it is made (its
// markup, the asset slots' table, the type icons, what a preview renders through), filled by the
// application. A page finds its
// markup's parts by id with Node.FindElement; an object's whole state is a snapshot (its own
// Serialize, which writes its versioned envelope itself), and an edit of it made by code that moves
// many values at once (a preset) one undo step. The editor's grids read components, settings and
// assets through the
// editor-side FieldPropertySource (the user's rulings, 2026-10-29), each edit a snapshot step.

/// What an asset page asks of the editor when it is made. The page that is given it owns it.
class AssetPageServices
{
	/// A page's markup by its path under the data root, a node with one reference the caller
	/// takes; null: none (a test), or it could not be read.
	public delegate Node(StringView path) LoadMarkup ~ delete _;
	/// The asset slots'; null: none. Not owned.
	public ResourceRefServices Refs = null;
	/// The type icons; null: none. Not owned.
	public EditorIcons Icons = null;
	/// What a page's preview renders through (the embedded runtime's host, with its scenes and
	/// renderer, the scene page's too) and its window's GUI, which hosts the preview's viewport;
	/// null: none, a test (the preview then draws nothing). Not owned.
	public IApplicationHost Host = null;
	public GuiHost Gui = null;
	/// The code editors' languages by id; null: none, a test (code shows uncoloured). Not owned.
	public CodeLanguages Languages = null;
	/// Opens the editor's picker for a request (a source file's Browse); OWNERSHIP of the request
	/// transfers. Null: none. Owned.
	public delegate void(PickerRequest request) Pick ~ delete _;
}

/// Where every page factory gets the services a page is made with: one, owned by the editor's
/// application (or a test) and outliving the factories, each of which keeps a borrowed reference and
/// asks it when it makes a page (the window, the host and the GUI exist by then). One source shared
/// by reference, where each factory once held a delegate of its own (and a library with two
/// factories had one ask the other's).
class AssetPageServicesSource
{
	private delegate AssetPageServices() mMake ~ delete _;

	/// None: a page made with no services (a test's registration).
	public this()
	{
	}

	/// Takes `make`, which makes the services a page is given.
	public this(delegate AssetPageServices() make)
	{
		mMake = make;
	}

	/// The services a page is made with now; the caller (the page) owns them.
	public AssetPageServices Make() => (mMake != null) ? mMake() : new AssetPageServices();
}

static class ObjectSnapshot
{
	/// `object`'s whole state as bytes, into `outBytes`.
	public static void Take(ISerializable object, List<uint8> outBytes)
	{
		outBytes.Clear();
		let stream = scope MemoryStream();
		let ar = scope BinarySerializer(stream, .Write);
		object.Serialize(ar);
		outBytes.AddRange(stream.Bytes);
	}

	/// Puts Take's `bytes` back into `object`; false when they did not read.
	public static bool Restore(ISerializable object, Span<uint8> bytes)
	{
		let stream = scope MemoryStream();
		stream.Write(bytes);
		stream.Seek(0, .Begin);
		let ar = scope BinarySerializer(stream, .Read);
		object.Serialize(ar);
		return ar.IsOk;
	}
}

/// An edit over a whole object: its state before and after, put back by undo and redo on the
/// object, found again each time; `applied` runs after each.
class ObjectSnapshotCommand : EditorCommand
{
	private delegate ISerializable() mTarget ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;
	private String mTypeId = new .() ~ delete _;
	private delegate void() mApplied ~ delete _;

	/// Takes `target` and `applied` (null: nothing after).
	public this(delegate ISerializable() target, Span<uint8> before, Span<uint8> after, StringView typeId, delegate void() applied = null)
	{
		mTarget = target;
		mBefore.AddRange(before);
		mAfter.AddRange(after);
		mTypeId.Set(typeId);
		mApplied = applied;
	}

	public override bool Execute() => Put(mAfter);

	public override void Undo()
	{
		Put(mBefore);
	}

	public override StringView TypeId => mTypeId;

	private bool Put(List<uint8> bytes)
	{
		let object = (mTarget != null) ? mTarget() : null;
		if (object == null)
			return false;
		let ok = ObjectSnapshot.Restore(object, bytes);
		if (mApplied != null)
			mApplied();
		return ok;
	}
}
