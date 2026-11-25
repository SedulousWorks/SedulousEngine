using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Dialogue;

/// A mood a speaker's lines may name, and its portrait (a texture; nil uses the speaker's).
[Reflect(.All)]
class DialogueMood : ISerializable
{
	[DisplayName("Name")]
	public String Name = new .() ~ delete _;
	[DisplayName("Portrait"), References("Sedulous.Texture.Resource.Texture")]
	public Guid Portrait = .();

	public this() {}

	public this(StringView name, Guid portrait)
	{
		Name.Set(name);
		Portrait = portrait;
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		SerializeValue(ar, "portrait", ref Portrait);
		ar.EndObject();
	}
}

/// One speaker: who a conversation's lines name, how the box shows them, and what they play.
[Reflect(.All)]
class DialogueSpeaker : ISerializable
{
	[DisplayName("Id"), Description("What a conversation's lines name the speaker by: one word")]
	public String Id = new .() ~ delete _;
	[DisplayName("Shown Name"), Description("The name the box shows; empty shows none")]
	public String ShownName = new .() ~ delete _;
	/// The box shows a name plate, tinted PlateColor.
	[DisplayName("Name Plate")]
	public bool Plate = true;
	[DisplayName("Plate Color"), AsColor]
	public Float4 PlateColor = .(0.5f, 0.5f, 0.5f, 1.0f);
	[DisplayName("Moods"), Description("The moods a line may name; the first is the default")]
	public List<DialogueMood> Moods = new .() ~ DeleteContainerAndItems!(_);
	[DisplayName("Portrait"), Description("For a mood without a portrait of its own"), References("Sedulous.Texture.Resource.Texture")]
	public Guid Portrait = .();
	[DisplayName("Clips"), Description("The animation clips a conversation may play, by name"), References("Sedulous.Animation.AnimationClip")]
	public List<Guid> Clips = new .() ~ delete _;
	/// A clip played while the speaker's line shows.
	[DisplayName("Talk Clip"), References("Sedulous.Animation.AnimationClip")]
	public Guid Talk = .();
	/// A sound played as the text types.
	[DisplayName("Voice"), References("Sedulous.Audio.AudioClip")]
	public Guid Voice = .();
	[DisplayName("Entity"), Description("The level entity that plays the speaker, by name")]
	public String Entity = new .() ~ delete _;

	/// The mood `name`, or null.
	public DialogueMood FindMood(StringView name)
	{
		for (let mood in Moods)
		{
			if (mood.Name == name)
				return mood;
		}
		return null;
	}

	public void Serialize(ISerializer ar)
	{
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "id", Id);
		Sedulous.Core.Serialization.Serialize(ar, "shownName", ShownName);
		SerializeValue(ar, "plate", ref Plate);
		SerializeValue(ar, "plateColor", ref PlateColor);
		ar.Key("moods");
		SerializeList(ar, Moods);
		SerializeValue(ar, "portrait", ref Portrait);
		ar.Key("clips");
		SerializeList(ar, Clips);
		SerializeValue(ar, "talk", ref Talk);
		SerializeValue(ar, "voice", ref Voice);
		Sedulous.Core.Serialization.Serialize(ar, "entity", Entity);
		ar.EndObject();
	}
}

/// The runtime product: a cast's speakers.
class DialogueCastResource
{
	public List<DialogueSpeaker> Speakers = new .() ~ DeleteContainerAndItems!(_);

	/// The speaker `id`, or null.
	public DialogueSpeaker Find(StringView id)
	{
		for (let speaker in Speakers)
		{
			if (speaker.Id == id)
				return speaker;
		}
		return null;
	}
}

/// The cooked form.
class DialogueCastSource : ISerializable
{
	public List<DialogueSpeaker> Speakers = new .() ~ DeleteContainerAndItems!(_);

	public void Serialize(ISerializer ar)
	{
		ar.Key("speakers");
		SerializeList(ar, Speakers);
	}
}

/// Loads a cooked DialogueCastSource into a DialogueCastResource: its speakers move in.
class DialogueCastFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<DialogueCastResource>();
	public Type CookedType => typeof(DialogueCastSource);

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;
		defer delete stored;
		let source = stored as DialogueCastSource;
		if (source == null)
			return null;
		let product = new DialogueCastResource();
		Swap!(product.Speakers, source.Speakers);
		return product;
	}
}

/// The dialogue's resources: the cooked dialogue file and cast, and their factories, as the domain
/// the Engine part adds to the engine's composition when it loads.
static class DialogueResources
{
	public static ResourceModule Module => sModule ?? (sModule = new .("dialogue", () => RegisterAll(), new .(
		.ByDefault<DialogueResource, DialogueSource, DialogueFactory>(),
		.ByDefault<DialogueCastResource, DialogueCastSource, DialogueCastFactory>())));
	private static ResourceModule sModule ~ delete _;

	/// The cooked forms into the global registry unless another is given.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf(typeof(DialogueSource).GetFullName(.. scope .())), () => new DialogueSource());
		target.Register(TypeIdOf(typeof(DialogueCastSource).GetFullName(.. scope .())), () => new DialogueCastSource());
	}
}
