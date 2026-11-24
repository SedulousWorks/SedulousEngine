using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Sequence;
using Sedulous.Sequence.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Sequence;

/// A sequence as bytes and back: what an undo step keeps, and how the preview takes a copy of its
/// own. The tracks are objects the sequence owns, so a step or a play holding the live ones would
/// lose them to the next rebuild.
static class SequenceBytes
{
	public static void Write(Sedulous.Sequence.Sequence sequence, List<uint8> outBytes)
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			sequence.Serialize(writer);
		}
		outBytes.Clear();
		outBytes.AddRange(stream.Bytes);
	}

	/// A new sequence read from `bytes`, OWNED by the caller, its tracks' assets bound through
	/// `resources` when given.
	public static Sedulous.Sequence.Sequence Read(Span<uint8> bytes, ResourceManager resources)
	{
		let stream = scope MemoryStream();
		stream.Write(bytes);
		stream.Seek(0, .Begin);
		let read = new Sedulous.Sequence.Sequence();
		{
			let reader = scope BinarySerializer(stream, .Read);
			read.Serialize(reader);
		}
		if (resources != null)
		{
			for (let track in read.Tracks)
				track.ResolveResources(resources);
		}
		return read;
	}

	/// A copy of `sequence`, OWNED by the caller.
	public static Sedulous.Sequence.Sequence Copy(Sedulous.Sequence.Sequence sequence, ResourceManager resources)
	{
		let bytes = scope List<uint8>();
		Write(sequence, bytes);
		return Read(bytes, resources);
	}
}

/// The sequence the panel edits. A sequence is an asset of its own, not part of the scene it plays
/// in, so it keeps its own history and its own unsaved mark, as a property animation clip does.
/// Every edit is one undo step that records the whole sequence before and after as its serialized
/// bytes: its tracks are objects the sequence owns, so a step holding them would see them change
/// or go. A gesture (dragging a key or a section) edits live and becomes one step when it ends, or
/// nothing when it is cancelled. Each change rebuilds the tracks the document holds, and its
/// version says so, so the preview begins its play again on the new ones.
class SequenceDocument
{
	// One step: the whole sequence before and after, as bytes.
	private class Step : EditorCommand
	{
		private SequenceDocument mDocument;
		private String mTypeId = new .() ~ delete _;
		private List<uint8> mBefore ~ delete _;
		private List<uint8> mAfter ~ delete _;

		/// Takes both.
		public this(SequenceDocument document, StringView typeId, List<uint8> before, List<uint8> after)
		{
			mDocument = document;
			mTypeId.Set(typeId);
			mBefore = before;
			mAfter = after;
		}

		public override bool Execute()
		{
			mDocument.Restore(mAfter);
			return true;
		}

		public override void Undo() => mDocument.Restore(mBefore);

		public override StringView TypeId => mTypeId;
	}

	private EditorContext mContext;
	private Sedulous.Sequence.Sequence mSequence = new .() ~ delete _;
	private Guid mId = .Empty;
	private String mName = new .() ~ delete _;
	/// The sequence's history, which keeps the place last saved (or loaded).
	private EditorCommandStack mCommands = new .() ~ delete _;
	/// A gesture's sequence as it began; null while none is open.
	private List<uint8> mGestureBefore = null ~ delete _;
	private uint64 mVersion = 0;

	/// Told after any change: an edit, a gesture's preview, an undo, a load.
	public delegate void() OnChanged ~ delete _;

	public this(EditorContext context)
	{
		mContext = context;
		// Told once the history has moved, so the unsaved mark is the history's new place.
		mCommands.OnChanged = new [=this] () => { Changed(); };
	}

	public bool HasSequence => mId != .Empty;
	public Guid SequenceId => mId;
	public StringView Name => mName;
	public bool IsDirty => HasSequence && !mCommands.IsAtSaved;
	/// BORROWED, and replaced by any change: ask again rather than keep it.
	public Sedulous.Sequence.Sequence Sequence => mSequence;
	public EditorCommandStack Commands => mCommands;
	public bool InGesture => mGestureBefore != null;
	/// Moves on whenever the tracks are rebuilt (an edit, an undo, a load): what a play began on the
	/// old ones must begin again.
	public uint64 Version => mVersion;

	/// The length it plays over: its authored duration or its content's, whichever is later (at
	/// least a second).
	public float Length => Math.Max(Math.Max(mSequence.Duration, mSequence.ComputeDuration()), 1.0f);

	/// Reads the sequence asset `sequenceId` (its history let go); false when there is no such
	/// sequence.
	public bool Load(Guid sequenceId)
	{
		let instance = (mContext.Project != null) ? mContext.Project.SourceDb.GetInstance(sequenceId) : null;
		let object = (instance != null) ? instance.ReadObject() : null;
		defer delete object;
		let asset = object as SequenceAsset;
		if (asset == null)
			return false;
		CancelGesture();
		// The read sequence is this document's alone: taken from the asset, which deletes the old.
		Swap!(mSequence, asset.Source.Sequence);
		if (let resources = mContext.Resources)
		{
			for (let track in mSequence.Tracks)
				track.ResolveResources(resources);
		}
		mId = sequenceId;
		mName.Set(instance.Name);
		mCommands.Clear();
		mCommands.MarkSaved();
		Changed();
		return true;
	}

	/// Writes the sequence to its asset and asks for a cook; it is then saved.
	public Result<void, ErrorCode> Save()
	{
		let instance = (HasSequence && (mContext.Project != null)) ? mContext.Project.SourceDb.GetInstance(mId) : null;
		if (instance == null)
			return .Err(.NotFound);
		let asset = scope SequenceAsset();
		// Lent for the write, which only reads it.
		Swap!(asset.Source.Sequence, mSequence);
		let written = instance.WriteObject(asset);
		Swap!(asset.Source.Sequence, mSequence);
		if (written case .Err(let error))
		{
			GlobalLog(.Warning, "Editor: writing the sequence '{}' failed", mName);
			return .Err(error);
		}
		mCommands.MarkSaved();
		mContext.RequestCook(false);
		Changed(); // the unsaved mark
		return .Ok;
	}

	/// No sequence, its history let go.
	public void Close()
	{
		CancelGesture();
		Replace(new .());
		mId = .Empty;
		mName.Clear();
		mCommands.Clear();
		mCommands.MarkSaved();
		Changed();
	}

	/// An edit made at once: `mutate` changes the sequence, one step (its duration grown to cover
	/// what it holds).
	public void Edit(StringView typeId, delegate void(Sedulous.Sequence.Sequence sequence) mutate)
	{
		if (!HasSequence || InGesture)
			return;
		let before = new List<uint8>();
		SequenceBytes.Write(mSequence, before);
		mutate(mSequence);
		Push(typeId, before);
	}

	/// A gesture: the sequence edited live (GestureSequence, then PreviewGesture to show it), one
	/// step when it commits; cancelled, the sequence as it was.
	public void BeginGesture()
	{
		if (!HasSequence)
			return;
		if (InGesture)
			CancelGesture();
		mGestureBefore = new .();
		SequenceBytes.Write(mSequence, mGestureBefore);
	}

	public Sedulous.Sequence.Sequence GestureSequence => mSequence;

	/// The tracks changed in place: the version moves on (Changed), so a play on them begins again.
	public void PreviewGesture() => Changed();

	public void CommitGesture(StringView typeId)
	{
		if (!InGesture)
			return;
		let before = mGestureBefore;
		mGestureBefore = null;
		Push(typeId, before);
	}

	public void CancelGesture()
	{
		if (!InGesture)
			return;
		Restore(mGestureBefore);
		DeleteAndNullify!(mGestureBefore);
		Changed();
	}

	// The sequence as it is now after `before` (taken), one step.
	private void Push(StringView typeId, List<uint8> before)
	{
		// The duration never cuts off what the sequence holds.
		mSequence.Duration = Math.Max(mSequence.Duration, mSequence.ComputeDuration());
		let after = new List<uint8>();
		SequenceBytes.Write(mSequence, after);
		mCommands.Execute(new Step(this, typeId, before, after));
	}

	// The history tells, once it has moved.
	private void Restore(List<uint8> bytes)
	{
		Replace(SequenceBytes.Read(bytes, mContext.Resources));
	}

	/// `sequence` (taken) in place of the one held, which is deleted. The version moves on with
	/// the change that follows (Changed).
	private void Replace(Sedulous.Sequence.Sequence sequence)
	{
		delete mSequence;
		mSequence = sequence;
	}

	private void Changed()
	{
		mVersion++;
		if (OnChanged != null)
			OnChanged();
	}
}
