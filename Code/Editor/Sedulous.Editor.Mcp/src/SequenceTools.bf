using System;
using System.Collections;
using System.Reflection;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;
using Sedulous.Sequence;
using Sedulous.Sequence.Pipeline;

namespace Sedulous.Editor.Mcp;

/// sequence_read / sequence_edit: a sequence asset for an agent, whatever its track kinds. The read
/// gives its parts, its markers and each track: its kind (by type name and by the name the editor
/// shows), its part, its key channels with their keys, its sections, and its reflected fields. The
/// edit takes a list of edits, applies them in order to the sequence as stored and writes it once; a
/// refused edit refuses the call and nothing is written. Kinds are the registered ones
/// (SequenceTracks.Kinds), and keys and sections go through each kind's own editing calls, so a kind
/// a domain or a plugin adds is read and edited with no list here. A field is read and set by its
/// reflected path ("Sections.0.Clip", "Keys.1.Name", "Color"), the fields the inspector edits.
static class SequenceTools
{
	public static void Register(McpServer server, ProjectSession session)
	{
		let readSchema = scope SchemaBuilder();
		readSchema.Str("guid", "the sequence's guid (asset_list: type SequenceAsset)", true);
		server.RegisterTool("sequence_read",
			"A sequence asset (a cutscene timeline): its length and frame rate, its parts (the cast's names, filled when it plays), its markers (a hold stops the playhead until the game resumes it), and each track by index: its kind (type name, and the name the editor shows), its part (null: the whole sequence), a property track's component and property, its key channels with their keys (a curve's with values), its sections, and its reflected `fields` (the paths sequence_edit's `set` takes, such as Sections.0.Clip). `kinds` lists every registered kind.",
			readSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) =>
			{
				let instance = Resolve(session, arguments, outError);
				if (instance == null)
					return false;
				let asset = Read(instance, outError);
				if (asset == null)
					return false;
				defer delete asset;
				SequenceJson(instance, asset.Source.Sequence, outResult);
				return true;
			});

		let editSchema = scope SchemaBuilder();
		editSchema.Str("guid", "the sequence's guid", true);
		editSchema.Arr("edits", "object", "the edits, in order", true);
		server.RegisterTool("sequence_edit",
			"Edit a sequence asset: `edits` is a list applied in order, then the sequence is written once; a refused edit refuses the call and nothing is written. Each edit is an object with `op`: length {seconds}; add_part {name}; remove_part {name}; add_track {kind (a kind's type or editor name), part (when the kind plays on one), name?, and for a property track component (Transform, or a component's name), property (a field path), valueKind (Float, Float3, Color, Quat; Transform's are known)}; remove_track {track}; key {track, channel (name or index; omit for one), time, value? (a curve's)}; remove_key {track, channel, time}; section {track, start, length?, fields? (the section's fields by name: Clip, Offset, Speed...)}; remove_section {track, section}; marker {time, name?, hold?}; remove_marker {marker}; set {track, path (a field's path from sequence_read, or part), value}. Returns each edit's result (the index it made) and the sequence as sequence_read gives it. An open sequence panel shows the write when it holds no unsaved edits; asset_cook before a game plays it.",
			editSchema.Build(), .Overwrites,
			new (arguments, outResult, outError) =>
			{
				let instance = Resolve(session, arguments, outError);
				if (instance == null)
					return false;
				let asset = Read(instance, outError);
				if (asset == null)
					return false;
				defer delete asset;
				let sequence = asset.Source.Sequence;
				let edits = arguments.Get("edits");
				let results = JsonValue.MakeArray();
				let count = ((edits != null) && edits.IsArray) ? edits.Count : 0;
				for (int i < count)
				{
					let result = JsonValue.MakeObject();
					let reason = scope String();
					if (!Apply(sequence, edits.At(i), result, reason))
					{
						delete result;
						delete results;
						outError.AppendF("edit {} refused - {}. Nothing was written.", i, reason);
						return false;
					}
					results.Add(result);
				}
				// It never cuts off what it holds.
				sequence.Duration = Math.Max(sequence.Duration, sequence.ComputeDuration());
				if (instance.WriteObject(asset) case .Err)
				{
					delete results;
					outError.AppendF("could not write '{}'", instance.Name);
					return false;
				}
				if (session.OnAssetWritten != null)
					session.OnAssetWritten(instance.Id);
				SequenceJson(instance, sequence, outResult);
				outResult.Set("results", results);
				return true;
			});
	}

	// === Reading ===

	/// The name a kind shows in the editor (its DisplayName), else its type name, appended.
	public static void KindLabel(Type kind, String outName)
	{
		if (kind.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
			outName.Append(shown.Name);
		else
			kind.GetName(outName);
	}

	private static void SequenceJson(Instance instance, Sedulous.Sequence.Sequence sequence, JsonValue outResult)
	{
		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("length", JsonValue.MakeNumber(Math.Max(sequence.Duration, sequence.ComputeDuration())));
		outResult.Set("frameRate", JsonValue.MakeNumber(sequence.FrameRate));
		let parts = JsonValue.MakeArray();
		for (let binding in sequence.Bindings)
			parts.Add(JsonValue.MakeString(binding.Name));
		outResult.Set("parts", parts);
		let markers = JsonValue.MakeArray();
		for (let marker in sequence.Markers)
		{
			let m = JsonValue.MakeObject();
			m.Set("time", JsonValue.MakeNumber(marker.Time));
			m.Set("name", JsonValue.MakeString(marker.Name));
			m.Set("hold", JsonValue.MakeBool(marker.Hold));
			markers.Add(m);
		}
		outResult.Set("markers", markers);
		let tracks = JsonValue.MakeArray();
		for (int t < sequence.Tracks.Count)
			tracks.Add(TrackJson(sequence, t));
		outResult.Set("tracks", tracks);
		let kinds = JsonValue.MakeArray();
		for (let kind in SequenceTracks.Kinds)
		{
			let k = JsonValue.MakeObject();
			k.Set("kind", JsonValue.MakeString(kind.GetName(.. scope .())));
			k.Set("kindName", JsonValue.MakeString(KindLabel(kind, .. scope .())));
			kinds.Add(k);
		}
		outResult.Set("kinds", kinds);
	}

	private static JsonValue TrackJson(Sedulous.Sequence.Sequence sequence, int index)
	{
		let track = sequence.Tracks[index];
		let json = JsonValue.MakeObject();
		json.Set("index", JsonValue.MakeNumber(index));
		json.Set("kind", JsonValue.MakeString(track.GetType().GetName(.. scope .())));
		json.Set("kindName", JsonValue.MakeString(KindLabel(track.GetType(), .. scope .())));
		json.Set("name", JsonValue.MakeString(track.Name));
		let bound = (track.Binding >= 0) && (track.Binding < sequence.Bindings.Count);
		json.Set("part", bound ? JsonValue.MakeString(sequence.Bindings[track.Binding].Name) : JsonValue.MakeNull());
		json.Set("muted", JsonValue.MakeBool(track.Muted));
		if (let property = track as PropertySequenceTrack)
		{
			json.Set("component", JsonValue.MakeString(property.Property.ComponentType));
			json.Set("property", JsonValue.MakeString(property.Property.PropertyPath));
		}
		let channels = JsonValue.MakeArray();
		let times = scope List<float>();
		for (int c < track.KeyChannelCount)
		{
			let channel = JsonValue.MakeObject();
			channel.Set("name", JsonValue.MakeString(track.GetKeyChannelName(c, .. scope .())));
			let keys = JsonValue.MakeArray();
			if (let curve = track.KeyCurve(c))
			{
				for (let key in curve.Keys)
				{
					let k = JsonValue.MakeObject();
					k.Set("time", JsonValue.MakeNumber(key.Time));
					k.Set("value", JsonValue.MakeNumber(key.Value));
					keys.Add(k);
				}
			}
			else
			{
				track.GetKeyTimes(c, times);
				for (let t in times)
				{
					let k = JsonValue.MakeObject();
					k.Set("time", JsonValue.MakeNumber(t));
					keys.Add(k);
				}
			}
			channel.Set("keys", keys);
			channels.Add(channel);
		}
		json.Set("channels", channels);
		let sections = JsonValue.MakeArray();
		for (int i < track.SectionCount)
		{
			let label = scope String();
			track.GetSection(i, let start, let length, label);
			let section = JsonValue.MakeObject();
			section.Set("start", JsonValue.MakeNumber(start));
			section.Set("length", JsonValue.MakeNumber(length));
			section.Set("label", JsonValue.MakeString(label));
			sections.Add(section);
		}
		json.Set("sections", sections);
		json.Set("fields", FieldJson.FieldsJson(track.GetType(), Internal.UnsafeCastToPtr(track)));
		return json;
	}

	private static Instance Resolve(ProjectSession session, JsonValue arguments, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return null;
		}
		if (!McpTools.ParseGuid(McpTools.ArgString(arguments, "guid", .. scope .()), outError, let id))
			return null;
		let instance = session.Project.SourceDb.GetInstance(id);
		if (instance == null)
			outError.AppendF("no asset with guid {} in the open project", id);
		return instance;
	}

	/// The sequence asset `instance` stores, OWNED by the caller; null (and why) when it is not one.
	private static SequenceAsset Read(Instance instance, String outError)
	{
		let object = instance.ReadObject();
		if (let asset = object as SequenceAsset)
			return asset;
		delete object;
		outError.AppendF("'{}' is not a sequence (asset_list's type SequenceAsset)", instance.Name);
		return null;
	}

	// === One edit ===

	private static SequenceTrack TrackArg(Sedulous.Sequence.Sequence sequence, JsonValue edit, String outError)
	{
		let arg = edit.Get("track");
		let index = (arg != null) ? arg.AsInt(-1) : -1;
		if ((arg == null) || !arg.IsNumber || (index < 0) || (index >= sequence.Tracks.Count))
		{
			outError.AppendF("`track` is a track's index (0 to {})", sequence.Tracks.Count - 1);
			return null;
		}
		return sequence.Tracks[(int)index];
	}

	private static bool ChannelArg(SequenceTrack track, JsonValue edit, out int channel, String outError)
	{
		channel = 0;
		let arg = edit.Get("channel");
		if (((arg == null) || arg.IsNull) && (track.KeyChannelCount == 1))
			return true;
		if ((arg != null) && arg.IsNumber && (arg.AsInt() >= 0) && (arg.AsInt() < track.KeyChannelCount))
		{
			channel = (int)arg.AsInt();
			return true;
		}
		let names = scope String();
		for (int c < track.KeyChannelCount)
		{
			let name = track.GetKeyChannelName(c, .. scope .());
			if ((arg != null) && arg.IsString && (arg.AsString() == name))
			{
				channel = c;
				return true;
			}
			if (c != 0)
				names.Append(", ");
			names.Append(name);
		}
		if (track.KeyChannelCount == 0)
			outError.Append("this track holds sections, not keys");
		else
			outError.AppendF("`channel` is one of: {} (or its index)", names);
		return false;
	}

	private static Type FindKind(StringView name)
	{
		for (let kind in SequenceTracks.Kinds)
		{
			if ((kind.GetName(.. scope .()) == name) || (KindLabel(kind, .. scope .()) == name))
				return kind;
		}
		return null;
	}

	private static void KindNames(String outNames)
	{
		for (let kind in SequenceTracks.Kinds)
		{
			if (!outNames.IsEmpty)
				outNames.Append(", ");
			KindLabel(kind, outNames);
		}
	}

	private static float Number(JsonValue edit, StringView key) => (edit.Get(key) != null) ? (float)edit.Get(key).AsNumber() : 0.0f;

	private static StringView Text(JsonValue edit, StringView key) => (edit.Get(key) != null) ? edit.Get(key).AsString() : "";

	private static bool Given(JsonValue edit, StringView key) => (edit.Get(key) != null) && !edit.Get(key).IsNull;

	/// Applies one edit; fills `result` with what it made (an index). False, and why, when refused.
	private static bool Apply(Sedulous.Sequence.Sequence sequence, JsonValue edit, JsonValue result, String outError)
	{
		if ((edit == null) || !edit.IsObject)
		{
			outError.Append("each edit is an object with `op`");
			return false;
		}
		let op = Text(edit, "op");
		switch (op)
		{
		case "length":
			sequence.Duration = Math.Max(0.0f, Number(edit, "seconds"));
			return true;
		case "add_part":
			let name = Text(edit, "name");
			if (name.IsEmpty || (sequence.FindBinding(name) >= 0))
			{
				outError.AppendF("add_part needs a `name` not already a part ('{}')", name);
				return false;
			}
			sequence.Bindings.Add(new .(name));
			result.Set("part", JsonValue.MakeNumber(sequence.Bindings.Count - 1));
			return true;
		case "remove_part":
			let part = sequence.FindBinding(Text(edit, "name"));
			if (part < 0)
			{
				outError.Append("remove_part: no part of that `name`");
				return false;
			}
			delete sequence.Bindings[part];
			sequence.Bindings.RemoveAt(part);
			for (let track in sequence.Tracks)
				track.Binding = (track.Binding == part) ? -1 : ((track.Binding > part) ? track.Binding - 1 : track.Binding);
			return true;
		case "add_track":
			return AddTrack(sequence, edit, result, outError);
		case "remove_track":
			if (TrackArg(sequence, edit, outError) == null)
				return false;
			let at = (int)edit.Get("track").AsInt();
			delete sequence.Tracks[at];
			sequence.Tracks.RemoveAt(at);
			return true;
		case "key":
			let track = TrackArg(sequence, edit, outError);
			if (track == null)
				return false;
			int channel = 0;
			if (!ChannelArg(track, edit, out channel, outError))
				return false;
			let index = track.InsertKey(channel, Number(edit, "time"));
			if (index < 0)
			{
				outError.Append("key: the channel takes no key");
				return false;
			}
			if ((edit.Get("value") != null) && edit.Get("value").IsNumber)
			{
				let curve = track.KeyCurve(channel);
				if (curve == null)
				{
					outError.Append("key: this channel's keys hold no number (set its fields instead)");
					return false;
				}
				curve.Keys[index].Value = Number(edit, "value");
				curve.ApplyTangentModes();
			}
			result.Set("key", JsonValue.MakeNumber(index));
			return true;
		case "remove_key":
			let track = TrackArg(sequence, edit, outError);
			if (track == null)
				return false;
			int channel = 0;
			if (!ChannelArg(track, edit, out channel, outError))
				return false;
			let times = scope List<float>();
			track.GetKeyTimes(channel, times);
			let time = Number(edit, "time");
			for (int i < times.Count)
			{
				if (Math.Abs(times[i] - time) < 1e-4f)
				{
					int[1] gone = .(i);
					track.DeleteKeys(channel, gone);
					return true;
				}
			}
			outError.AppendF("remove_key: no key at {} on that channel", time);
			return false;
		case "section":
			let track = TrackArg(sequence, edit, outError);
			if (track == null)
				return false;
			if (track.KeyChannelCount != 0)
			{
				outError.Append("section: this track holds keys, not sections");
				return false;
			}
			let start = Number(edit, "start");
			let index = track.AddSection(start);
			if (index < 0)
			{
				outError.Append("section: this kind takes no more sections (set its fields instead)");
				return false;
			}
			if ((edit.Get("length") != null) && edit.Get("length").IsNumber)
				track.SetSection(index, start, Number(edit, "length"));
			let fields = edit.Get("fields");
			if ((fields != null) && fields.IsObject)
			{
				for (let key in fields.Keys)
				{
					let path = scope String()..AppendF("Sections.{}.{}", index, key);
					if (!SetPath(track, path, fields.Get(key), outError))
						return false;
				}
			}
			result.Set("section", JsonValue.MakeNumber(index));
			return true;
		case "remove_section":
			let track = TrackArg(sequence, edit, outError);
			if (track == null)
				return false;
			let index = (edit.Get("section") != null) ? edit.Get("section").AsInt(-1) : -1;
			let before = track.SectionCount;
			if ((index < 0) || (index >= before))
			{
				outError.AppendF("remove_section: `section` is an index (0 to {})", before - 1);
				return false;
			}
			track.RemoveSection((int)index);
			if (track.SectionCount == before)
			{
				outError.Append("remove_section: this kind keeps its section");
				return false;
			}
			return true;
		case "marker":
			let time = Math.Max(0.0f, Number(edit, "time"));
			int at = 0;
			while ((at < sequence.Markers.Count) && (sequence.Markers[at].Time <= time))
				at++;
			let name = Given(edit, "name") ? Text(edit, "name") : "marker";
			let hold = (edit.Get("hold") != null) && edit.Get("hold").AsBool();
			sequence.Markers.Insert(at, new .(time, name, hold));
			result.Set("marker", JsonValue.MakeNumber(at));
			return true;
		case "remove_marker":
			let index = (edit.Get("marker") != null) ? edit.Get("marker").AsInt(-1) : -1;
			if ((index < 0) || (index >= sequence.Markers.Count))
			{
				outError.AppendF("remove_marker: `marker` is an index (0 to {})", sequence.Markers.Count - 1);
				return false;
			}
			delete sequence.Markers[(int)index];
			sequence.Markers.RemoveAt((int)index);
			return true;
		case "set":
			let track = TrackArg(sequence, edit, outError);
			if (track == null)
				return false;
			if (Text(edit, "path") == "part")
			{
				let value = edit.Get("value");
				let named = ((value != null) && !value.IsNull);
				track.Binding = named ? sequence.FindBinding(value.AsString()) : -1;
				if (named && (track.Binding < 0))
				{
					outError.Append("set part: no part of that name");
					return false;
				}
				return true;
			}
			return SetPath(track, Text(edit, "path"), edit.Get("value"), outError);
		default:
			outError.AppendF("`op` '{}' is not one of: length, add_part, remove_part, add_track, remove_track, key, remove_key, section, remove_section, marker, remove_marker, set", op);
			return false;
		}
	}

	private static bool AddTrack(Sedulous.Sequence.Sequence sequence, JsonValue edit, JsonValue result, String outError)
	{
		let kind = FindKind(Text(edit, "kind"));
		if (kind == null)
		{
			outError.AppendF("add_track: `kind` is one of: {}", KindNames(.. scope .()));
			return false;
		}
		let made = GlobalSerializableRegistry.Create(TypeIdOf(kind.GetFullName(.. scope .())));
		let track = made as SequenceTrack;
		if (track == null)
		{
			delete made;
			outError.Append("add_track: the kind could not be made");
			return false;
		}
		if (Given(edit, "part"))
		{
			track.Binding = sequence.FindBinding(Text(edit, "part"));
			if (track.Binding < 0)
			{
				delete track;
				outError.Append("add_track: no part of that `part` name (add_part first)");
				return false;
			}
		}
		else if (track.NeedsBinding)
		{
			outError.AppendF("add_track: a {} track plays on a part: give `part`", KindLabel(kind, .. scope .()));
			delete track;
			return false;
		}
		if (let property = track as PropertySequenceTrack)
		{
			property.Property.ComponentType.Set(Text(edit, "component"));
			property.Property.PropertyPath.Set(Text(edit, "property"));
			if (property.Property.ComponentType.IsEmpty || property.Property.PropertyPath.IsEmpty)
			{
				delete track;
				outError.Append("add_track: a property track needs `component` (or Transform) and `property`");
				return false;
			}
			let transform = property.Property.ComponentType == TrackTargets.cTransform;
			switch (Text(edit, "valueKind"))
			{
			case "Float": property.Property.Kind = .Float;
			case "Float3": property.Property.Kind = .Float3;
			case "Color": property.Property.Kind = .Color;
			case "Quat": property.Property.Kind = .Quat;
			default:
				if (transform)
					property.Property.Kind = (property.Property.PropertyPath == "Rotation") ? .Quat : .Float3;
				else
				{
					delete track;
					outError.Append("add_track: give `valueKind` (Float, Float3, Color or Quat) for a component's property");
					return false;
				}
			}
		}
		if (Given(edit, "name"))
			track.Name.Set(Text(edit, "name"));
		sequence.Tracks.Add(track);
		result.Set("track", JsonValue.MakeNumber(sequence.Tracks.Count - 1));
		return true;
	}

	// === Writing a field by its path ===

	/// Sets the field at `path` under `track` ("Sections.0.Clip"): fields by name, list elements by
	/// index; the value in the shape sequence_read shows it.
	private static bool SetPath(SequenceTrack track, StringView path, JsonValue value, String outError)
	{
		Type type = track.GetType();
		void* address = Internal.UnsafeCastToPtr(track);
		// Whether `address` holds a reference to an object (a field or element of a class type)
		// rather than being the value itself.
		var holdsObject = false;
		let segments = scope List<StringView>();
		for (let part in path.Split('.'))
			segments.Add(part);
		for (int s < segments.Count)
		{
			let segment = segments[s];
			let last = s == segments.Count - 1;
			if (holdsObject)
			{
				let obj = *(Object*)address;
				if (obj == null)
				{
					outError.AppendF("'{}': nothing at '{}'", path, segment);
					return false;
				}
				if (let list = obj as IReflectedList)
				{
					if (!(int.Parse(segment) case .Ok(let index)) || (index < 0) || (index >= list.Count))
					{
						outError.AppendF("'{}': '{}' is not an element's index (0 to {})", path, segment, list.Count - 1);
						return false;
					}
					type = list.ElementType;
					address = list.ElementAddress(index);
					holdsObject = type.IsObject && (type != typeof(String));
					if (last)
						return WriteLeaf(type, address, value, path, outError);
					continue;
				}
				type = obj.GetType();
				address = Internal.UnsafeCastToPtr(obj);
			}
			if (!(type.GetField(scope String(segment)) case .Ok(let field)) || !FieldJson.IsShown(field))
			{
				outError.AppendF("'{}': no field '{}' (sequence_read's `fields` names them)", path, segment);
				return false;
			}
			type = field.FieldType;
			address = (uint8*)address + field.MemberOffset;
			if (last)
				return WriteLeaf(type, address, value, path, outError);
			holdsObject = type.IsObject && (type != typeof(String));
		}
		outError.AppendF("'{}' names no field", path);
		return false;
	}

	private static bool WriteLeaf(Type type, void* address, JsonValue value, StringView path, String outError)
	{
		if (ReferenceShape.Is(type))
		{
			var id = Guid();
			if ((value != null) && !value.IsNull && !(value.IsString && (Guid.Parse(value.AsString()) case .Ok(out id))))
			{
				outError.AppendF("'{}' is an asset reference: give an asset guid, or null", path);
				return false;
			}
			ReferenceShape.Assign(type, address, id, null).IgnoreError();
			return true;
		}
		if (type == typeof(EntityRef))
		{
			var id = Guid();
			if ((value != null) && !value.IsNull && !(value.IsString && (Guid.Parse(value.AsString()) case .Ok(out id))))
			{
				outError.AppendF("'{}' is an entity reference: give an entity guid, or null", path);
				return false;
			}
			*(EntityRef*)address = EntityRef(id);
			return true;
		}
		if (type.IsEnum)
		{
			if (!FieldJson.EnumValueOf(type, value, let raw))
			{
				outError.AppendF("'{}' takes one of: {}", path, FieldJson.EnumNames(type, .. scope .()));
				return false;
			}
			RawFieldAccess.WriteRawInt(address, type.Size, raw);
			return true;
		}
		if (type == typeof(String))
		{
			let text = *(String*)address;
			if ((value == null) || !value.IsString || (text == null))
			{
				outError.AppendF("'{}' is text: give a string", path);
				return false;
			}
			text.Set(value.AsString());
			return true;
		}
		var leaf = FieldJson.LeafVariant(type, value);
		defer leaf.Dispose();
		if (!leaf.HasValue)
		{
			outError.AppendF("'{}' is a {}: give it in the shape sequence_read shows", path, type.GetName(.. scope .()));
			return false;
		}
		leaf.CopyValueData(address);
		return true;
	}
}
