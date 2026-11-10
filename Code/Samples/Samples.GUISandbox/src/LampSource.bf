using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.GUI;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;

namespace Samples.GUISandbox;

// The Toolkit page's property source: three lamps,
// an application's own objects, behind a selection of one or all of them, with the undo an
// application keeps (every lamp as it was before and after each change, one entry whatever the
// gesture previewed). Its paths:
//   - name, a read-only id, enabled, type (an enum), intensity, range, shadows (flags), bounces;
//   - position, a Float3; rotation, a Float3 of Euler degrees over a stored Quaternion, the source
//     converting as the editor's Transform row does; cone, a Float2 shown only on spots (changing
//     the type tells the grid its properties changed);
//   - tags, a list of text of at most four; effects, a list of two types (Flicker, Pulse), each a
//     group of its own values;
//   - flicker, a curve of Core's keys: its row a preview, its editor the toolkit's curve view;
//   - falloff, hinted "falloff", which no editor takes.
// Each lamp's defaults are how it started; a revert puts them back. Copying writes a path and what
// is under it with the engine's XmlSerializer, a shape first, so a paste refuses another shape.
// The page's clip writes sampled values into the lamps (SetAnimatedValue) as it is scrubbed, with no
// history: the grid follows.

class LampSource : IPropertySource
{
	public const int cLamps = 3;
	public const int cMostTags = 4;

	private struct Effect
	{
		public int64 Type = 0; // 0 Flicker, 1 Pulse
		public double Speed = 4.0;
		public double Amount = 0.25;
		public double Period = 1.0;

		public this(int64 type, double speed, double amount, double period)
		{
			Type = type;
			Speed = speed;
			Amount = amount;
			Period = period;
		}
	}

	private static Effect Flicker() => .(0, 4.0, 0.25, 1.0);
	private static Effect Pulse() => .(1, 1.0, 0.5, 2.0);

	/// One lamp. A class: it owns its name and its lists; Set copies another into it.
	private class Lamp
	{
		public String Name = new .() ~ delete _;
		public int64 Id = 0;
		public bool Enabled = true;
		public int64 Type = 0;
		public double Intensity = 5.0;
		public double Range = 10.0;
		public double[2] Cone = .(20.0, 35.0);
		public int64 Shadows = 0b001;
		public double[3] Position = .(0.0, 0.0, 0.0);
		public Quaternion Rotation = .Identity;
		public List<String> Tags = new .() ~ DeleteContainerAndItems!(_);
		public List<Effect> Effects = new .() ~ delete _;
		public int64 Bounces = 2;
		public List<CurveKey> FlickerCurve = new .() ~ delete _;

		public void Set(Lamp other)
		{
			if (other === this)
				return;
			Name.Set(other.Name);
			Id = other.Id;
			Enabled = other.Enabled;
			Type = other.Type;
			Intensity = other.Intensity;
			Range = other.Range;
			Cone = other.Cone;
			Shadows = other.Shadows;
			Position = other.Position;
			Rotation = other.Rotation;
			SetTags(other.Tags);
			Effects.Clear();
			Effects.AddRange(other.Effects);
			Bounces = other.Bounces;
			FlickerCurve.Clear();
			FlickerCurve.AddRange(other.FlickerCurve);
		}

		public void SetTags(List<String> tags)
		{
			if (tags === Tags)
				return;
			ClearAndDeleteItems!(Tags);
			for (let tag in tags)
				Tags.Add(new String(tag));
		}

		public Lamp Clone()
		{
			let copy = new Lamp();
			copy.Set(this);
			return copy;
		}
	}

	/// What each selected lamp held at `Path` when an edit began: owned values, for a cancel.
	private class Original
	{
		public String Path = new .() ~ delete _;
		public List<Sedulous.GUI.Variant> Values = new .() ~ { for (var value in ref _) value.Dispose(); delete _; };
	}

	/// A change: every lamp as it was before and after, and what it was, in words.
	private class Entry
	{
		public String Words = new .() ~ delete _;
		public List<Lamp> Before = new .() ~ DeleteContainerAndItems!(_);
		public List<Lamp> After = new .() ~ DeleteContainerAndItems!(_);
	}

	private Lamp[cLamps] mLamps;
	private Lamp[cLamps] mDefaults;
	private List<int> mSelection = new .() ~ delete _;
	private List<Original> mOriginals = new .() ~ DeleteContainerAndItems!(_);
	private List<Entry> mUndo = new .() ~ DeleteContainerAndItems!(_);
	private List<Entry> mRedo = new .() ~ DeleteContainerAndItems!(_);
	private delegate void(StringView words) mOnHistory ~ delete _;

	public this()
	{
		StringView[cLamps] names = .("Lamp A", "Lamp B", "Lamp C");
		for (int i < cLamps)
		{
			mLamps[i] = new Lamp();
			mDefaults[i] = new Lamp();
			let lamp = mLamps[i];
			lamp.Name.Set(names[i]);
			lamp.Id = 101 + (int64)i;
			lamp.Position[0] = (double)i * 2.0;
			lamp.Position[1] = 3.0;
			lamp.Tags.Add(new String("indoor"));
			// A flicker over a second: bright, a dip, a recovery, a smaller dip.
			float[6] times = .(0.0f, 0.15f, 0.3f, 0.55f, 0.8f, 1.0f);
			float[6] values = .(1.0f, 0.4f, 0.9f, 0.55f, 1.0f, 0.8f);
			for (int k < 6)
			{
				var key = CurveKey(times[k], values[k], .Cubic);
				key.TangentMode = .Auto;
				lamp.FlickerCurve.Add(key);
			}
			ApplyCurveTangentModes(lamp.FlickerCurve);
		}
		// The second differs in intensity, type, a shadow flag, its turn and its effects, so all
		// three show them mixed.
		mLamps[1].Intensity = 12.5;
		mLamps[1].Type = 1;
		mLamps[1].Shadows = 0b011;
		mLamps[1].Rotation = FromYawPitchRoll(DegreesToRadians(30.0f), 0.0f, 0.0f);
		mLamps[1].Effects.Add(Pulse());
		mLamps[2].Enabled = false;
		for (int i < cLamps)
			mDefaults[i].Set(mLamps[i]); // how each started is its default
		SetSelection(0);
	}

	public ~this()
	{
		for (int i < cLamps)
		{
			delete mLamps[i];
			delete mDefaults[i];
		}
	}

	/// Edits lamp `lamp`, or all of them with cLamps.
	public void SetSelection(int lamp)
	{
		mSelection.Clear();
		for (int i < cLamps)
		{
			if ((lamp >= cLamps) || (lamp == i))
				mSelection.Add(i);
		}
		NotifyPropertiesChanged();
	}

	public bool CanUndo => !mUndo.IsEmpty;
	public bool CanRedo => !mRedo.IsEmpty;
	public void Undo() => Step(mUndo, mRedo, true);
	public void Redo() => Step(mRedo, mUndo, false);

	/// A value the page's clip plays into lamp `lamp` at `path`: shown, kept in no history.
	public void SetAnimatedValue(int lamp, StringView path, double value)
	{
		if ((lamp < 0) || (lamp >= cLamps))
			return;
		Write(mLamps[lamp], path, Sedulous.GUI.Variant(value));
		NotifyValuesChanged();
	}

	/// The lamp named `name` (Lamp A, B or C); cLamps when none is.
	public int FindLamp(StringView name)
	{
		for (int i < cLamps)
		{
			if (mLamps[i].Name == name)
				return i;
		}
		return cLamps;
	}

	/// Told when the history changes (to enable Undo and Redo) and what changed, in words.
	/// OWNERSHIP of `changed` transfers.
	public void SetOnHistoryChanged(delegate void(StringView words) changed)
	{
		delete mOnHistory;
		mOnHistory = changed;
	}

	// === IPropertySource ===

	public override int ObjectCount => mSelection.Count;

	public override void GetProperties(StringView parent, List<PropertyInfo> outInfos)
	{
		if (parent == "position")
		{
			Add(outInfos, "x", .Float, "", "X").Step = 0.1;
			Add(outInfos, "y", .Float, "", "Y").Step = 0.1;
			Add(outInfos, "z", .Float, "", "Z").Step = 0.1;
			return;
		}
		if (parent == "rotation")
		{
			Add(outInfos, "pitch", .Float, "", "Pitch");
			Add(outInfos, "yaw", .Float, "", "Yaw");
			Add(outInfos, "roll", .Float, "", "Roll");
			return;
		}
		if (parent == "cone")
		{
			StringView[2] parts = .("inner", "outer");
			for (let part in parts)
			{
				let angle = Add(outInfos, part, .Float, "", (part == "inner") ? "Inner" : "Outer");
				angle.HasRange = true;
				angle.Min = 1.0;
				angle.Max = 179.0;
			}
			return;
		}
		if (parent == "tags")
		{
			for (int i < Fewest(true))
				Add(outInfos, scope $"{i}", .String, "", scope $"Tag {i + 1}");
			return;
		}
		if (parent == "effects")
		{
			for (int i < Fewest(false))
				Add(outInfos, scope $"{i}", .Group, "", (Lead.Effects[i].Type == 0) ? "Flicker" : "Pulse");
			return;
		}
		if (EffectIndex(parent) case .Ok(let index))
		{
			if (index >= Lead.Effects.Count)
				return;
			if (Lead.Effects[index].Type == 0)
			{
				Add(outInfos, "speed", .Float, "", "Speed").Step = 0.1;
				Add(outInfos, "amount", .Float, "", "Amount").Step = 0.05;
			}
			else
				Add(outInfos, "period", .Float, "", "Period").Step = 0.1;
			return;
		}
		if (parent.Length != 0)
			return;

		Add(outInfos, "name", .String, "", "Name").Description.Set("What the scene calls it");
		let id = Add(outInfos, "id", .Integer, "", "Id");
		id.ReadOnly = true;
		id.Description.Set("Given by the scene: read only");
		Add(outInfos, "enabled", .Bool, "Light", "Enabled");
		let type = Add(outInfos, "type", .Enum, "Light", "Type");
		type.AddChoice("Point", 0);
		type.AddChoice("Spot", 1);
		type.AddChoice("Area", 2);
		let intensity = Add(outInfos, "intensity", .Float, "Light", "Intensity");
		intensity.HasRange = true;
		intensity.Min = 0.0;
		intensity.Max = 100.0;
		intensity.Step = 0.5;
		intensity.Description.Set("Drag across it to scrub; Escape gives the scrub up");
		Add(outInfos, "range", .Float, "Light", "Range").Step = 0.25;
		let flicker = Add(outInfos, "flicker", .Curve, "Light", "Flicker");
		flicker.HasRange = true;
		flicker.Min = 0.0;
		flicker.Max = 1.5;
		flicker.MaxCount = 8;
		flicker.Description.Set("Its brightness over a second: click for the curve");
		let cone = Add(outInfos, "cone", .Group, "Light", "Cone");
		cone.Hint.Set("Float2");
		cone.Visible = AllSpots;
		cone.Description.Set("Only a spot has one: its inner and outer angles");
		let shadows = Add(outInfos, "shadows", .Flags, "Light", "Shadows");
		shadows.AddChoice("Cast", 1);
		shadows.AddChoice("Receive", 2);
		shadows.AddChoice("Static", 4);
		Add(outInfos, "position", .Group, "Transform", "Position").Hint.Set("Float3");
		let rotation = Add(outInfos, "rotation", .Group, "Transform", "Rotation");
		rotation.Hint.Set("Float3");
		rotation.Description.Set("Euler degrees over the lamp's Quaternion");
		let tags = Add(outInfos, "tags", .List, "Lists", "Tags");
		tags.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
		tags.MaxCount = (uint32)cMostTags;
		tags.Description.Set("At most four");
		let effects = Add(outInfos, "effects", .List, "Lists", "Effects");
		effects.ListOps = PropertyListAdd | PropertyListRemove | PropertyListMove;
		effects.ElementTypes.Add(new String("Flicker"));
		effects.ElementTypes.Add(new String("Pulse"));
		Add(outInfos, "bounces", .Integer, "Advanced", "Bounces").Description.Set("An integer: no range, snapped to whole numbers");
		let falloff = Add(outInfos, "falloff", .Group, "Advanced", "Falloff");
		falloff.Hint.Set("falloff"); // a hint no editor takes: the row says so
		falloff.Description.Set("A hint no editor takes");
	}

	public override Sedulous.GUI.Variant GetValue(StringView path, int object)
	{
		return (object < mSelection.Count) ? ValueOf(mLamps[mSelection[object]], path).Copy() : .();
	}

	public override void BeginEdit(StringView path)
	{
		let original = new Original();
		original.Path.Set(path);
		for (let lamp in mSelection)
			original.Values.Add(Read(mLamps[lamp], path).Copy());
		mOriginals.Add(original);
	}

	public override void PreviewEdit(StringView path, PropertyWrite write)
	{
		for (let lamp in mSelection)
			Write(mLamps[lamp], path, ApplyPropertyWrite(Read(mLamps[lamp], path), write));
		Changed(path);
	}

	public override void CommitEdit(StringView path, PropertyWrite write)
	{
		if (let original = FindOriginal(path))
		{
			for (int i = 0; (i < mSelection.Count) && (i < original.Values.Count); i++)
				Write(mLamps[mSelection[i]], path, original.Values[i]); // the originals back first
		}
		DropOriginal(path);
		Change(scope $"Set {path}", path, scope (lamp, index) =>
			{
				Write(lamp, path, ApplyPropertyWrite(Read(lamp, path), write));
			});
	}

	public override void CancelEdit(StringView path)
	{
		if (let original = FindOriginal(path))
		{
			for (int i = 0; (i < mSelection.Count) && (i < original.Values.Count); i++)
				Write(mLamps[mSelection[i]], path, original.Values[i]);
		}
		DropOriginal(path);
		Changed(path);
	}

	public override bool EditList(StringView path, ListEdit edit)
	{
		let tags = path == "tags";
		if (!tags && (path != "effects"))
			return false;
		bool changed = false;
		let words = scope String();
		switch (edit.Kind)
		{
		case .Insert: words.AppendF("Added to {}", path);
		case .Remove: words.AppendF("Removed from {}", path);
		case .Move: words.AppendF("Moved in {}", path);
		}
		Change(words, "type", scope [&] (lamp, index) => // the rows change: read again
			{
				if (tags)
					changed = EditTags(lamp.Tags, edit) || changed;
				else
					changed = EditEffects(lamp.Effects, edit) || changed;
			});
		if (!changed)
			DropLast();
		return changed;
	}

	public override Sedulous.GUI.Variant GetDefault(StringView path, int object)
	{
		if ((object >= mSelection.Count) || (path == "id")) // the scene's id is no default
			return .();
		return ValueOf(mDefaults[mSelection[object]], path).Copy();
	}

	public override bool Revert(StringView path)
	{
		bool changed = false;
		Change(scope $"Reverted {path}", "type", scope [&] (lamp, index) =>
			{
				let before = scope Lamp();
				before.Set(lamp);
				PutUnder(lamp, mDefaults[index], path);
				changed = changed || !Same(before, lamp);
			});
		if (!changed)
			DropLast();
		return changed;
	}

	public override void GetRevertText(StringView path, String outText)
	{
		outText.Append("Revert to how it started");
	}

	// `path` and what is under it, the first lamp's, written with the engine's XmlSerializer: its
	// shape, a list's count and its effects' types, then each value under its path from here.
	public override void CopyValue(StringView path, String outText)
	{
		if (mSelection.IsEmpty || (path == "falloff"))
			return;
		// Written from a copy: writing reads it alone, and the floats' helper takes one to write to.
		let lamp = scope Lamp();
		lamp.Set(Lead);
		let ar = scope XmlSerializer();
		let shape = ShapeOf(path, .. scope String());
		Serialize(ar, "shape", shape);
		if ((path == "tags") || (path == "effects"))
		{
			int64 count = (path == "tags") ? lamp.Tags.Count : lamp.Effects.Count;
			SerializeValue(ar, "count", ref count);
			if (path == "effects")
			{
				for (int i < (int)count)
				{
					int64 type = lamp.Effects[i].Type;
					SerializeValue(ar, scope $"{i}.type", ref type);
				}
			}
		}
		let leaves = scope List<String>();
		defer { ClearAndDeleteItems!(leaves); }
		LeavesOf(lamp, path, leaves);
		if ((shape == "Float2") || (shape == "Float3"))
			SerializeFloats(ar, lamp, leaves, shape == "Float3");
		else
		{
			for (let leaf in leaves)
				SerializeLeaf(ar, Relative(path, leaf, .. scope String()), lamp, leaf);
		}
		if (!ar.IsOk)
			return;
		ar.GetOutput(outText);
	}

	public override bool PasteValue(StringView path, StringView text, String reason)
	{
		let doc = scope XmlDocument();
		let shape = scope String();
		let parsed = doc.Parse(text) == .Ok;
		if (parsed)
		{
			let probe = scope XmlSerializer(doc);
			Serialize(probe, "shape", shape);
		}
		if (shape.Length == 0)
		{
			reason.Set("The clipboard holds no copied property");
			return false;
		}
		if (path == "id")
		{
			reason.Set("The id is read only");
			return false;
		}
		let expected = ShapeOf(path, .. scope String());
		if (shape != expected)
		{
			reason.Clear();
			reason.AppendF("A {} does not paste onto {}", shape, expected);
			return false;
		}
		// Read into a copy of the first lamp, then give every selected lamp the same.
		let ar = scope XmlSerializer(doc);
		Serialize(ar, "shape", shape);
		let pasted = scope Lamp();
		pasted.Set(Lead);
		if ((path == "tags") || (path == "effects"))
		{
			int64 count = 0;
			SerializeValue(ar, "count", ref count);
			count = Math.Clamp(count, 0, (path == "tags") ? (int64)cMostTags : 64);
			if (path == "tags")
			{
				ClearAndDeleteItems!(pasted.Tags);
				for (int i < (int)count)
					pasted.Tags.Add(new String());
			}
			else
			{
				pasted.Effects.Clear();
				for (int i < (int)count)
				{
					int64 type = 0;
					SerializeValue(ar, scope $"{i}.type", ref type);
					pasted.Effects.Add((type == 1) ? Pulse() : Flicker());
				}
			}
		}
		let leaves = scope List<String>();
		defer { ClearAndDeleteItems!(leaves); }
		LeavesOf(pasted, path, leaves);
		if ((shape == "Float2") || (shape == "Float3"))
			SerializeFloats(ar, pasted, leaves, shape == "Float3");
		else
		{
			for (let leaf in leaves)
				SerializeLeaf(ar, Relative(path, leaf, .. scope String()), pasted, leaf);
		}
		if (!ar.IsOk)
		{
			reason.Set("The copied values do not fit");
			return false;
		}
		Change(scope $"Pasted {path}", "type", scope (lamp, index) => { PutUnder(lamp, pasted, path); });
		return true;
	}

	// === Lamps ===

	private static PropertyInfo Add(List<PropertyInfo> outInfos, StringView name, PropertyKind kind, StringView category, StringView shown)
	{
		let info = new PropertyInfo();
		info.Name.Set(name);
		info.DisplayName.Set(shown);
		info.Kind = kind;
		info.Category.Set(category);
		outInfos.Add(info);
		return info;
	}

	private Lamp Lead => mLamps[mSelection.IsEmpty ? 0 : mSelection[0]];

	private bool AllSpots
	{
		get
		{
			for (let lamp in mSelection)
			{
				if (mLamps[lamp].Type != 1)
					return false;
			}
			return !mSelection.IsEmpty;
		}
	}

	// The fewest tags (or effects) any selected lamp has: the elements shown.
	private int Fewest(bool tags)
	{
		int count = int.MaxValue;
		for (let lamp in mSelection)
			count = Math.Min(count, tags ? mLamps[lamp].Tags.Count : mLamps[lamp].Effects.Count);
		return mSelection.IsEmpty ? 0 : count;
	}

	// "effects.2" -> 2.
	private static Result<int> EffectIndex(StringView path)
	{
		if (ElementOf(path, "effects", let index, let field) && (field.Length == 0))
			return .Ok(index);
		return .Err;
	}

	// "tags.1" -> 1; "effects.0.speed" -> 0 and "speed".
	private static bool ElementOf(StringView path, StringView list, out int index, out StringView field)
	{
		index = 0;
		field = default;
		if ((path.Length <= list.Length + 1) || (path.Substring(0, list.Length) != list) || (path[list.Length] != '.'))
			return false;
		var rest = path.Substring(list.Length + 1);
		for (int i < rest.Length)
		{
			if (rest[i] == '.')
			{
				field = rest.Substring(i + 1);
				rest = rest.Substring(0, i);
				break;
			}
		}
		if (!(int64.Parse(rest) case .Ok(let parsed)) || (parsed < 0))
			return false;
		index = (int)parsed;
		return true;
	}

	// A value as the grid reads it: a list's is its count. A view of the lamp's.
	private static Sedulous.GUI.Variant ValueOf(Lamp lamp, StringView path)
	{
		if (path == "tags")
			return .((int64)lamp.Tags.Count);
		if (path == "effects")
			return .((int64)lamp.Effects.Count);
		return Read(lamp, path);
	}

	// The value at `path`: a view of the lamp's text and keys, valid while it is unchanged.
	private static Sedulous.GUI.Variant Read(Lamp lamp, StringView path)
	{
		switch (path)
		{
		case "name": return .((StringView)lamp.Name);
		case "id": return .(lamp.Id);
		case "enabled": return .(lamp.Enabled);
		case "type": return .(lamp.Type);
		case "intensity": return .(lamp.Intensity);
		case "range": return .(lamp.Range);
		case "cone.inner": return .(lamp.Cone[0]);
		case "cone.outer": return .(lamp.Cone[1]);
		case "shadows": return .(lamp.Shadows);
		case "bounces": return .(lamp.Bounces);
		case "flicker": return Sedulous.GUI.Variant.FromCurve(lamp.FlickerCurve);
		case "position.x": return .(lamp.Position[0]);
		case "position.y": return .(lamp.Position[1]);
		case "position.z": return .(lamp.Position[2]);
		case "rotation.pitch": return .((double)EulerDegrees(lamp.Rotation).X);
		case "rotation.yaw": return .((double)EulerDegrees(lamp.Rotation).Y);
		case "rotation.roll": return .((double)EulerDegrees(lamp.Rotation).Z);
		default:
		}
		if (ElementOf(path, "tags", var index, var field))
			return ((index < lamp.Tags.Count) && (field.Length == 0)) ? Sedulous.GUI.Variant((StringView)lamp.Tags[index]) : .();
		if (ElementOf(path, "effects", out index, out field) && (index < lamp.Effects.Count))
		{
			let effect = lamp.Effects[index];
			if ((field == "speed") && (effect.Type == 0))
				return .(effect.Speed);
			if ((field == "amount") && (effect.Type == 0))
				return .(effect.Amount);
			if ((field == "period") && (effect.Type == 1))
				return .(effect.Period);
		}
		return .();
	}

	// Writes `value` (it may be a view of the lamp's own text or keys: copied before they change).
	private static void Write(Lamp lamp, StringView path, Sedulous.GUI.Variant value)
	{
		if (value.IsEmpty)
			return;
		switch (path)
		{
		case "name":
			let text = scope String(value.AsString);
			lamp.Name.Set(text);
		case "enabled": lamp.Enabled = value.AsBool;
		case "type": lamp.Type = value.AsInt;
		case "intensity": lamp.Intensity = value.AsFloat;
		case "range": lamp.Range = value.AsFloat;
		case "cone.inner": lamp.Cone[0] = value.AsFloat;
		case "cone.outer": lamp.Cone[1] = value.AsFloat;
		case "shadows": lamp.Shadows = value.AsInt;
		case "bounces": lamp.Bounces = value.AsInt;
		case "flicker":
			if (value.Kind == .Curve)
			{
				let keys = scope List<CurveKey>();
				keys.AddRange(value.AsCurve);
				lamp.FlickerCurve.Clear();
				lamp.FlickerCurve.AddRange(keys);
			}
		case "position.x": lamp.Position[0] = value.AsFloat;
		case "position.y": lamp.Position[1] = value.AsFloat;
		case "position.z": lamp.Position[2] = value.AsFloat;
		case "rotation.pitch", "rotation.yaw", "rotation.roll":
			// One angle set, the other two kept as they read now, as the editor's Transform row does.
			var euler = EulerDegrees(lamp.Rotation);
			let degrees = (float)value.AsFloat;
			if (path == "rotation.pitch")
				euler.X = degrees;
			else if (path == "rotation.yaw")
				euler.Y = degrees;
			else
				euler.Z = degrees;
			lamp.Rotation = FromYawPitchRoll(DegreesToRadians(euler.Y), DegreesToRadians(euler.X), DegreesToRadians(euler.Z));
		default:
			if (ElementOf(path, "tags", var index, var field))
			{
				if ((index < lamp.Tags.Count) && (field.Length == 0))
				{
					let tag = scope String(value.AsString);
					lamp.Tags[index].Set(tag);
				}
			}
			else if (ElementOf(path, "effects", out index, out field) && (index < lamp.Effects.Count))
			{
				let effect = &lamp.Effects[index];
				if (field == "speed")
					effect.Speed = value.AsFloat;
				else if (field == "amount")
					effect.Amount = value.AsFloat;
				else if (field == "period")
					effect.Period = value.AsFloat;
			}
		}
	}

	private static Float3 EulerDegrees(Quaternion q)
	{
		ToYawPitchRoll(q, let yaw, let pitch, let roll);
		return .(RadiansToDegrees(pitch), RadiansToDegrees(yaw), RadiansToDegrees(roll));
	}

	// An insert, a removal or a move of a lamp's tags; whether it changed them.
	private static bool EditTags(List<String> list, ListEdit edit)
	{
		switch (edit.Kind)
		{
		case .Insert:
			if (list.Count < cMostTags)
			{
				list.Insert(Math.Clamp(edit.Index, 0, list.Count), new String("new"));
				return true;
			}
		case .Remove:
			if ((edit.Index >= 0) && (edit.Index < list.Count))
			{
				delete list[edit.Index];
				list.RemoveAt(edit.Index);
				return true;
			}
		case .Move:
			if ((edit.Index >= 0) && (edit.Index < list.Count) && (edit.To >= 0) && (edit.To < list.Count) && (edit.Index != edit.To))
			{
				let moved = list[edit.Index];
				list.RemoveAt(edit.Index);
				list.Insert(edit.To, moved);
				return true;
			}
		}
		return false;
	}

	// An insert (of the element type the edit names), a removal or a move of a lamp's effects.
	private static bool EditEffects(List<Effect> list, ListEdit edit)
	{
		switch (edit.Kind)
		{
		case .Insert:
			list.Insert(Math.Clamp(edit.Index, 0, list.Count), (edit.ElementType == "Pulse") ? Pulse() : Flicker());
			return true;
		case .Remove:
			if ((edit.Index >= 0) && (edit.Index < list.Count))
			{
				list.RemoveAt(edit.Index);
				return true;
			}
		case .Move:
			if ((edit.Index >= 0) && (edit.Index < list.Count) && (edit.To >= 0) && (edit.To < list.Count) && (edit.Index != edit.To))
			{
				let moved = list[edit.Index];
				list.RemoveAt(edit.Index);
				list.Insert(edit.To, moved);
				return true;
			}
		}
		return false;
	}

	// The value paths under `path` in `lamp` (itself when it is one), appended as new strings.
	private void LeavesOf(Lamp lamp, StringView path, List<String> outLeaves)
	{
		if (path == "tags")
		{
			for (int i < lamp.Tags.Count)
				outLeaves.Add(new String()..AppendF("tags.{}", i));
			return;
		}
		if (path == "effects")
		{
			for (int i < lamp.Effects.Count)
				LeavesOf(lamp, scope $"effects.{i}", outLeaves);
			return;
		}
		if (EffectIndex(path) case .Ok(let index))
		{
			if (index >= lamp.Effects.Count)
				return;
			if (lamp.Effects[index].Type == 0)
			{
				outLeaves.Add(new String()..AppendF("{}.speed", path));
				outLeaves.Add(new String()..AppendF("{}.amount", path));
			}
			else
				outLeaves.Add(new String()..AppendF("{}.period", path));
			return;
		}
		let children = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(children); }
		GetProperties(path, children);
		if (children.IsEmpty)
		{
			outLeaves.Add(new String(path));
			return;
		}
		for (let child in children)
			LeavesOf(lamp, JoinPropertyPath(path, child.Name, .. scope String()), outLeaves);
	}

	// `from`'s values put into `lamp` at `path` and under it; a list whole.
	private void PutUnder(Lamp lamp, Lamp from, StringView path)
	{
		if (path == "tags")
		{
			lamp.SetTags(from.Tags);
			return;
		}
		if (path == "effects")
		{
			lamp.Effects.Clear();
			lamp.Effects.AddRange(from.Effects);
			return;
		}
		let leaves = scope List<String>();
		defer { ClearAndDeleteItems!(leaves); }
		LeavesOf(from, path, leaves);
		for (let leaf in leaves)
		{
			if (leaf != "id")
				Write(lamp, leaf, Read(from, leaf));
		}
	}

	private static bool Same(Lamp a, Lamp b)
	{
		if ((a.Name != b.Name) || (a.Enabled != b.Enabled) || (a.Type != b.Type) || (a.Intensity != b.Intensity) || (a.Range != b.Range) ||
			(a.Cone[0] != b.Cone[0]) || (a.Cone[1] != b.Cone[1]) || (a.Shadows != b.Shadows) || (a.Bounces != b.Bounces) ||
			(a.Tags.Count != b.Tags.Count) || (a.Effects.Count != b.Effects.Count) ||
			(Sedulous.GUI.Variant.FromCurve(a.FlickerCurve).Compare(Sedulous.GUI.Variant.FromCurve(b.FlickerCurve)) != 0))
			return false;
		for (int i < 3)
		{
			if (a.Position[i] != b.Position[i])
				return false;
		}
		if ((a.Rotation.X != b.Rotation.X) || (a.Rotation.Y != b.Rotation.Y) || (a.Rotation.Z != b.Rotation.Z) || (a.Rotation.W != b.Rotation.W))
			return false;
		for (int i < a.Tags.Count)
		{
			if (a.Tags[i] != b.Tags[i])
				return false;
		}
		for (int i < a.Effects.Count)
		{
			let x = a.Effects[i];
			let y = b.Effects[i];
			if ((x.Type != y.Type) || (x.Speed != y.Speed) || (x.Amount != y.Amount) || (x.Period != y.Period))
				return false;
		}
		return true;
	}

	// What a copy of `path` is, so a paste refuses another shape: a group's hint, a list's name, an
	// effect's type, else a value's kind; appended to `outText`.
	private void ShapeOf(StringView path, String outText)
	{
		if ((path == "position") || (path == "rotation"))
		{
			outText.Append("Float3");
			return;
		}
		if (path == "cone")
		{
			outText.Append("Float2");
			return;
		}
		if ((path == "tags") || (path == "effects"))
		{
			outText.AppendF("list of {}", path);
			return;
		}
		if (EffectIndex(path) case .Ok(let index))
		{
			outText.Append(((index < Lead.Effects.Count) && (Lead.Effects[index].Type == 1)) ? "Pulse" : "Flicker");
			return;
		}
		switch (Read(Lead, path).Kind)
		{
		case .Bool: outText.Append("bool");
		case .Int: outText.Append("integer");
		case .Float: outText.Append("number");
		case .String: outText.Append("text");
		case .Curve: outText.Append("curve");
		default: outText.Append("value");
		}
	}

	// `leaf`'s path from `path` ("value" for `path` itself), appended to `outText`.
	private static void Relative(StringView path, StringView leaf, String outText)
	{
		if (leaf.Length == path.Length)
			outText.Append("value");
		else
			outText.Append(leaf.Substring(path.Length + 1));
	}

	// A Float2 or a Float3 either way as Core's own value (its x, y, z), its parts taken in order,
	// so one pastes onto another whatever its parts are called (a position onto a rotation's Euler
	// degrees).
	private static void SerializeFloats(ISerializer ar, Lamp lamp, List<String> leaves, bool three)
	{
		float Part(int i) => (i < leaves.Count) ? (float)Read(lamp, leaves[i]).AsFloat : 0.0f;
		void Put(int i, float value)
		{
			if (i < leaves.Count)
				Write(lamp, leaves[i], Sedulous.GUI.Variant((double)value));
		}
		if (three)
		{
			var value = Float3(Part(0), Part(1), Part(2));
			SerializeValue(ar, "value", ref value);
			if (ar.Mode == .Read)
			{
				Put(0, value.X);
				Put(1, value.Y);
				Put(2, value.Z);
			}
		}
		else
		{
			var value = Float2(Part(0), Part(1));
			SerializeValue(ar, "value", ref value);
			if (ar.Mode == .Read)
			{
				Put(0, value.X);
				Put(1, value.Y);
			}
		}
	}

	// The lamp's value at `leaf` either way under `key`, in the type it has (a read keeps the value's
	// type and writes it into the lamp).
	private static void SerializeLeaf(ISerializer ar, StringView key, Lamp lamp, StringView leaf)
	{
		let value = Read(lamp, leaf);
		let reading = ar.Mode == .Read;
		switch (value.Kind)
		{
		case .Bool:
			var flag = value.AsBool;
			SerializeValue(ar, key, ref flag);
			if (reading)
				Write(lamp, leaf, .(flag));
		case .Int:
			var integer = value.AsInt;
			SerializeValue(ar, key, ref integer);
			if (reading)
				Write(lamp, leaf, .(integer));
		case .Float:
			var number = value.AsFloat;
			SerializeValue(ar, key, ref number);
			if (reading)
				Write(lamp, leaf, .(number));
		case .String:
			let text = scope String(value.AsString);
			Serialize(ar, key, text);
			if (reading)
				Write(lamp, leaf, .((StringView)text));
		case .Curve:
			// Its count, then each key's fields, under the key's own object.
			let keys = scope List<CurveKey>();
			keys.AddRange(value.AsCurve);
			ar.Key(key);
			ar.BeginObject();
			int64 count = keys.Count;
			SerializeValue(ar, "count", ref count);
			count = Math.Clamp(count, 0, (int64)64);
			while (keys.Count < count)
				keys.Add(CurveKey());
			while (keys.Count > count)
				keys.PopBack();
			for (int i < keys.Count)
			{
				ar.Key(scope $"k{i}");
				ar.BeginObject();
				let k = &keys[i];
				SerializeValue(ar, "time", ref k.Time);
				SerializeValue(ar, "value", ref k.Value);
				SerializeValue(ar, "tangentIn", ref k.TangentIn);
				SerializeValue(ar, "tangentOut", ref k.TangentOut);
				int64 interpolation = (int64)k.Interpolation;
				int64 mode = (int64)k.TangentMode;
				SerializeValue(ar, "interpolation", ref interpolation);
				SerializeValue(ar, "tangentMode", ref mode);
				k.Interpolation = (CurveKeyInterpolation)interpolation;
				k.TangentMode = (CurveTangentMode)mode;
				ar.EndObject();
			}
			ar.EndObject();
			if (reading)
				Write(lamp, leaf, Sedulous.GUI.Variant.FromCurve(keys));
		default:
		}
	}

	// The selected lamps changed by `change` (given each lamp and its index), kept as one entry of
	// the history.
	private void Change(StringView words, StringView path, delegate void(Lamp lamp, int index) change)
	{
		let entry = new Entry();
		entry.Words.Set(words);
		for (let lamp in mLamps)
			entry.Before.Add(lamp.Clone());
		for (let lamp in mSelection)
			change(mLamps[lamp], lamp);
		for (let lamp in mLamps)
			entry.After.Add(lamp.Clone());
		mUndo.Add(entry);
		ClearAndDeleteItems!(mRedo);
		Changed(path);
		if (mOnHistory != null)
			mOnHistory(words);
	}

	// The last entry changed nothing: it goes.
	private void DropLast()
	{
		if (!mUndo.IsEmpty)
			delete mUndo.PopBack();
		if (mOnHistory != null)
			mOnHistory("Nothing changed");
	}

	// A type's change shows or hides the cone, and a list's change its rows: the properties changed,
	// not only values.
	private void Changed(StringView path)
	{
		if (path == "type")
			NotifyPropertiesChanged();
		else
			NotifyValuesChanged();
	}

	private Original FindOriginal(StringView path)
	{
		for (let original in mOriginals)
		{
			if (original.Path == path)
				return original;
		}
		return null;
	}

	private void DropOriginal(StringView path)
	{
		for (int i < mOriginals.Count)
		{
			if (mOriginals[i].Path == path)
			{
				delete mOriginals[i];
				mOriginals.RemoveAt(i);
				return;
			}
		}
	}

	private void Step(List<Entry> from, List<Entry> to, bool undo)
	{
		if (from.IsEmpty)
			return;
		let entry = from.PopBack();
		let state = undo ? entry.Before : entry.After;
		for (int i = 0; (i < cLamps) && (i < state.Count); i++)
			mLamps[i].Set(state[i]);
		let words = scope String();
		words.AppendF(undo ? "Undid: {}" : "Redid: {}", entry.Words);
		to.Add(entry);
		NotifyPropertiesChanged();
		if (mOnHistory != null)
			mOnHistory(words);
	}
}
