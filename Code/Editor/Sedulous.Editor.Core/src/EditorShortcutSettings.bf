using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// One shortcut the user rebound: the action's id and the chord as a binding writes it
/// ("ctrl-shift-z"; empty is "no shortcut", on purpose, distinct from the declaration's
/// default).
///
/// Version 2 keeps the chord as that text; version 1, written before the editor moved onto the
/// GUI, kept Sedulous.UI's key code and modifier bits, which read once as their keys and save
/// as text after. HAND WRITTEN rather than generated: the body branches on the stored version.
class ShortcutOverrideEntry : ISerializable
{
	/// The identity the generated attribute emitted, from the qualified name.
	public static readonly uint64 TypeId =
		Sedulous.Core.Serialization.TypeIdOf("Sedulous.Editor.Core.ShortcutOverrideEntry");
	public const uint32 DataVersion = 2;
	/// The oldest layout the reader below still understands.
	public const uint32 MinReadDataVersion = 1;

	public String Id = new .() ~ delete _;
	public String Keys = new .() ~ delete _;

	public EditorShortcut Chord => EditorShortcut.Of(Keys);

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.BeginVersionedPayload(ar, TypeId, DataVersion, MinReadDataVersion);
		if (!ar.IsPayloadOk)
		{
			Sedulous.Core.Serialization.EndVersionedPayload(ar);
			return;
		}
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "id", Id);
		if (ar.Version >= 2)
			Sedulous.Core.Serialization.Serialize(ar, "keys", Keys);
		else
		{
			uint32 key = 0;
			uint32 modifiers = 0;
			SerializeValue(ar, "key", ref key);
			SerializeValue(ar, "modifiers", ref modifiers);
			Keys.Clear();
			LegacyChordKeys(key, modifiers, Keys);
		}
		ar.EndObject();
		Sedulous.Core.Serialization.EndVersionedPayload(ar);
	}

	/// A chord version 1 kept, Sedulous.UI's key code (SDL's scancode, the USB HID usage) and
	/// modifier bits (SDL's: Shift 0x0003, Ctrl 0x00C0, Alt 0x0300, Gui 0x0C00), appended to
	/// `outKeys` as the binding text the keymap reads ("ctrl-t"), the modifiers in the order
	/// KeystrokeName writes them so the text saves back unchanged. Nothing for a key the GUI
	/// does not name (a modifier key alone, the keypad's equals) or no key at all.
	public static void LegacyChordKeys(uint32 key, uint32 modifiers, String outKeys)
	{
		let name = scope String();
		if ((key >= 4) && (key <= 29))
			name.Append((char8)((uint32)'a' + (key - 4)));
		else if ((key >= 30) && (key <= 38))
			name.Append((char8)((uint32)'1' + (key - 30)));
		else if ((key >= 58) && (key <= 69))
			name.AppendF("f{}", key - 57);
		else if ((key >= 104) && (key <= 115))
			name.AppendF("f{}", key - 91);
		else if ((key >= 89) && (key <= 97))
			name.AppendF("numpad{}", key - 88);
		else
		{
			switch (key)
			{
			case 39: name.Append("0");
			case 40: name.Append("enter");
			case 41: name.Append("escape");
			case 42: name.Append("backspace");
			case 43: name.Append("tab");
			case 44: name.Append("space");
			case 45: name.Append("minus");
			case 46: name.Append("equals");
			case 47: name.Append("leftbracket");
			case 48: name.Append("rightbracket");
			case 49: name.Append("backslash");
			case 51: name.Append("semicolon");
			case 52: name.Append("apostrophe");
			case 53: name.Append("grave");
			case 54: name.Append("comma");
			case 55: name.Append("period");
			case 56: name.Append("slash");
			case 57: name.Append("capslock");
			case 70: name.Append("printscreen");
			case 71: name.Append("scrolllock");
			case 72: name.Append("pause");
			case 73: name.Append("insert");
			case 74: name.Append("home");
			case 75: name.Append("pageup");
			case 76: name.Append("delete");
			case 77: name.Append("end");
			case 78: name.Append("pagedown");
			case 79: name.Append("right");
			case 80: name.Append("left");
			case 81: name.Append("down");
			case 82: name.Append("up");
			case 83: name.Append("numlock");
			case 84: name.Append("numpaddivide");
			case 85: name.Append("numpadmultiply");
			case 86: name.Append("numpadminus");
			case 87: name.Append("numpadplus");
			case 88: name.Append("numpadenter");
			case 98: name.Append("numpad0");
			case 99: name.Append("numpaddecimal");
			case 101: name.Append("menu");
			}
		}
		if (name.IsEmpty)
			return;
		if ((modifiers & 0x00C0) != 0)
			outKeys.Append("ctrl-");
		if ((modifiers & 0x0003) != 0)
			outKeys.Append("shift-");
		if ((modifiers & 0x0300) != 0)
			outKeys.Append("alt-");
		if ((modifiers & 0x0C00) != 0)
			outKeys.Append("super-");
		outKeys.Append(name);
	}
}

/// The user's shortcut overrides (Preferences > Shortcuts), keyed by action id, a settings
/// section. Captured from the registry on Save, applied to it after every domain has
/// registered its actions (an id nobody registered, a domain not loaded in this build, stays
/// in the section untouched, so a later run still has it).
[Serializable(1)]
class EditorShortcutSettings
{
	public List<ShortcutOverrideEntry> Overrides = new .() ~ DeleteContainerAndItems!(_);

	public ShortcutOverrideEntry Find(StringView id)
	{
		for (let entry in Overrides)
		{
			if (entry.Id == id)
				return entry;
		}
		return null;
	}

	/// The registry's overrides into the section: every registered action with one is written
	/// (added or updated), a registered one without is removed (reset to the default); an entry
	/// for an id the registry does not know is kept. Returns how many entries the section
	/// holds after.
	public int Capture(EditorActionRegistry actions)
	{
		for (let action in actions.Actions)
		{
			var entry = Find(action.Id);
			if (!actions.HasOverride(action.Id))
			{
				if (entry != null)
				{
					Overrides.Remove(entry);
					delete entry;
				}
				continue;
			}
			if (entry == null)
			{
				entry = new ShortcutOverrideEntry();
				entry.Id.Set(action.Id);
				Overrides.Add(entry);
			}
			entry.Keys.Clear();
			actions.Shortcut(action.Id).Keys(entry.Keys);
		}
		return Overrides.Count;
	}

	/// The section's overrides into the registry, entry by entry through Rebind: an unknown id
	/// is skipped silently (a domain not loaded), a collision is logged and skipped (the other
	/// action keeps the chord). Returns how many bound.
	public int ApplyTo(EditorActionRegistry actions)
	{
		int applied = 0;
		for (let entry in Overrides)
		{
			EditorActionDeclaration holder;
			switch (actions.Rebind(entry.Id, entry.Chord, out holder))
			{
			case .Ok:
				applied++;
			case .Err(let error):
				if ((error == .AlreadyExists) && (holder != null))
					GlobalLog(.Warning, scope $"Editor: shortcut override for '{entry.Id}' skipped: '{holder.Id}' holds {entry.Chord}");
			}
		}
		return applied;
	}
}

/// The Preferences page's staged shortcut edits, a chord chosen per action or a reset to the
/// default, applied together on Save. Applying first frees every staged action's chord, so two
/// actions can swap chords in one save; a chord another (unstaged) action holds is a
/// collision: that action keeps it, the staged one goes back to what it had, and the collision
/// is reported ("Ctrl+S: 'Save' holds it"). The registry's overrides are then captured into
/// the section for the store.
class ShortcutEdits
{
	public class Entry
	{
		public String Id = new .() ~ delete _;
		public bool Reset;
		public EditorShortcut Chord;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	public int Count => mEntries.Count;
	public bool IsEmpty => mEntries.IsEmpty;

	public void Set(StringView id, EditorShortcut chord)
	{
		let entry = Stage(id);
		entry.Reset = false;
		entry.Chord = chord;
	}

	public void Reset(StringView id)
	{
		let entry = Stage(id);
		entry.Reset = true;
		entry.Chord = .();
	}

	public void Discard(StringView id)
	{
		let entry = Pending(id);
		if (entry != null)
		{
			mEntries.Remove(entry);
			delete entry;
		}
	}

	public Entry Pending(StringView id)
	{
		for (let entry in mEntries)
		{
			if (entry.Id == id)
				return entry;
		}
		return null;
	}

	/// Returns how many edits took effect; the collisions, one line each, appended to
	/// `collisions` when given. The edits are consumed.
	public int Apply(EditorActionRegistry actions, EditorShortcutSettings section, List<String> collisions = null)
	{
		// What each staged action had, to give back on a collision.
		let hadOverride = scope bool[mEntries.Count];
		let previous = scope EditorShortcut[mEntries.Count];
		for (int i < mEntries.Count)
		{
			let id = mEntries[i].Id;
			hadOverride[i] = actions.HasOverride(id);
			previous[i] = actions.Shortcut(id);
			actions.Rebind(id, .()).IgnoreError(); // freed, so swaps work
		}
		int applied = 0;
		for (int i < mEntries.Count)
		{
			let entry = mEntries[i];
			if (actions.Find(entry.Id) == null)
				continue;
			if (entry.Reset)
			{
				actions.ResetShortcut(entry.Id);
				applied++;
				continue;
			}
			EditorActionDeclaration holder;
			if (actions.Rebind(entry.Id, entry.Chord, out holder) case .Ok)
			{
				applied++;
				continue;
			}
			// Back to what it had.
			if (hadOverride[i])
				actions.Rebind(entry.Id, previous[i]).IgnoreError();
			else
				actions.ResetShortcut(entry.Id);
			if ((collisions != null) && (holder != null))
				collisions.Add(new $"{entry.Chord}: '{holder.Label}' holds it");
		}
		ClearAndDeleteItems!(mEntries);
		section.Capture(actions);
		return applied;
	}

	private Entry Stage(StringView id)
	{
		var entry = Pending(id);
		if (entry == null)
		{
			entry = new Entry();
			entry.Id.Set(id);
			mEntries.Add(entry);
		}
		return entry;
	}
}
