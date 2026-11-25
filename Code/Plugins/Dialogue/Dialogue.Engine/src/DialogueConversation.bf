using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Dialogue;

/// What a step does. The runner walks a conversation's steps from the first; a step that waits (a
/// line, a choice, a wait, and what is told to wait) stops it until it is let go.
enum DialogueStepKind : uint8
{
	/// `Speaker` says the line `LineId` in `Mood`; waits for advance.
	case Line;
	/// Offers the `Count` Answer steps that follow; waits for a choice.
	case Choice;
	/// One answer, `LineId`; its statements start at `Next`.
	case Answer;
	/// Goes on at `Next` (the end of a choice's answer, the end of an if's side).
	case Skip;
	/// Goes on at `Next` unless `Flag` is set (is clear, with `Negate`).
	case If;
	/// Sets `Flag`.
	case Set;
	/// Clears `Flag`.
	case Clear;
	/// Waits `Seconds`.
	case Wait;
	/// `Speaker` plays the clip `Asset` (named `Name`) once; waits with `Waits`.
	case Play;
	/// Plays the sound `Asset`, at `Speaker`'s entity when one is named.
	case Sound;
	/// Fades in (`FadeIn`) or out over `Seconds` to `Color`.
	case Fade;
	/// Plays the sequence `Asset`; waits with `Waits`.
	case Sequence;
	/// Ends this conversation and plays the one named `Name`.
	case Jump;
	/// The declared command `Name` with its `Arguments`; waits with `Waits`, or leaves.
	case Command;
	/// The conversation's end.
	case End;
}

/// One argument of a declared command, converted to its kind by the cook.
class DialogueArgument : ISerializable
{
	/// The form's name for it ("who").
	public String Name = new .() ~ delete _;
	/// As written (every kind keeps it).
	public String Text = new .() ~ delete _;
	public float Number = 0.0f;
	/// An asset kind's guid.
	public Guid Asset = .();
	/// An optional part (`[running]`) was written.
	public bool Present = false;

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		Sedulous.Core.Serialization.Serialize(ar, "text", Text);
		SerializeValue(ar, "number", ref Number);
		SerializeValue(ar, "asset", ref Asset);
		SerializeValue(ar, "present", ref Present);
		ar.EndObject();
	}
}

/// One compiled statement. Which fields mean anything depends on the kind (see each kind).
class DialogueStep : ISerializable
{
	public DialogueStepKind Kind = .End;
	/// A cast id.
	public String Speaker = new .() ~ delete _;
	public String Mood = new .() ~ delete _;
	public String LineId = new .() ~ delete _;
	public String Flag = new .() ~ delete _;
	public bool Negate = false;
	/// A clip's, a conversation's or a command's name.
	public String Name = new .() ~ delete _;
	public Guid Asset = .();
	/// A wait's, or a fade's length; below 0, the settings' default.
	public float Seconds = -1.0f;
	public bool Waits = false;
	public bool Leaves = false;
	public bool FadeIn = false;
	/// A fade names its colour; otherwise the settings'.
	public bool HasColor = false;
	public Float4 Color = .(0.0f, 0.0f, 0.0f, 1.0f);
	/// Where a Skip, If or Answer goes on.
	public int32 Next = -1;
	/// A Choice's answers.
	public uint32 Count = 0;
	/// The line of the source text it came from, for messages.
	public uint32 SourceLine = 0;
	public List<DialogueArgument> Arguments = new .() ~ DeleteContainerAndItems!(_);

	public this() {}

	public this(DialogueStepKind kind)
	{
		Kind = kind;
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		var kind = (uint8)Kind;
		SerializeValue(ar, "kind", ref kind);
		Kind = (kind <= (uint8)DialogueStepKind.End) ? (DialogueStepKind)kind : .End;
		Sedulous.Core.Serialization.Serialize(ar, "speaker", Speaker);
		Sedulous.Core.Serialization.Serialize(ar, "mood", Mood);
		Sedulous.Core.Serialization.Serialize(ar, "lineId", LineId);
		Sedulous.Core.Serialization.Serialize(ar, "flag", Flag);
		SerializeValue(ar, "negate", ref Negate);
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		SerializeValue(ar, "asset", ref Asset);
		SerializeValue(ar, "seconds", ref Seconds);
		SerializeValue(ar, "waits", ref Waits);
		SerializeValue(ar, "leaves", ref Leaves);
		SerializeValue(ar, "fadeIn", ref FadeIn);
		SerializeValue(ar, "hasColor", ref HasColor);
		SerializeValue(ar, "color", ref Color);
		SerializeValue(ar, "next", ref Next);
		SerializeValue(ar, "count", ref Count);
		SerializeValue(ar, "sourceLine", ref SourceLine);
		ar.Key("arguments");
		SerializeList(ar, Arguments);
		ar.EndObject();
	}
}

/// A conversation: its id, the level its entity names are checked against (when it names one), and
/// its steps.
class DialogueConversation : ISerializable
{
	public String Id = new .() ~ delete _;
	public String Level = new .() ~ delete _;
	public List<DialogueStep> Steps = new .() ~ DeleteContainerAndItems!(_);

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "id", Id);
		Sedulous.Core.Serialization.Serialize(ar, "level", Level);
		ar.Key("steps");
		SerializeList(ar, Steps);
		ar.EndObject();
	}
}

/// A line's or an answer's text by its id: apart from the steps, where a translation will go.
class DialogueLineText : ISerializable
{
	public String Id = new .() ~ delete _;
	public String Text = new .() ~ delete _;

	public this() {}

	public this(StringView id, StringView text)
	{
		Id.Set(id);
		Text.Set(text);
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "id", Id);
		Sedulous.Core.Serialization.Serialize(ar, "text", Text);
		ar.EndObject();
	}
}

/// The runtime product: one dialogue file's conversations and texts, shared by every play.
class DialogueResource
{
	public List<DialogueConversation> Conversations = new .() ~ DeleteContainerAndItems!(_);
	public List<DialogueLineText> Lines = new .() ~ DeleteContainerAndItems!(_);

	/// The conversation `id`, or null.
	public DialogueConversation Find(StringView id)
	{
		for (let conversation in Conversations)
		{
			if (conversation.Id == id)
				return conversation;
		}
		return null;
	}

	/// The text of the line or answer `id`; empty when it has none.
	public StringView Text(StringView id)
	{
		for (let line in Lines)
		{
			if (line.Id == id)
				return line.Text;
		}
		return "";
	}
}

/// The cooked form.
class DialogueSource : ISerializable
{
	public List<DialogueConversation> Conversations = new .() ~ DeleteContainerAndItems!(_);
	public List<DialogueLineText> Lines = new .() ~ DeleteContainerAndItems!(_);

	public void Serialize(ISerializer ar)
	{
		ar.Key("conversations");
		SerializeList(ar, Conversations);
		ar.Key("lines");
		SerializeList(ar, Lines);
	}
}

/// Loads a cooked DialogueSource into a DialogueResource: its conversations and texts move in.
class DialogueFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<DialogueResource>();
	public Type CookedType => typeof(DialogueSource);

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;
		let source = stored as DialogueSource;
		if (source == null)
			return null;
		let product = new DialogueResource();
		Swap!(product.Conversations, source.Conversations);
		Swap!(product.Lines, source.Lines);
		return product;
	}
}
