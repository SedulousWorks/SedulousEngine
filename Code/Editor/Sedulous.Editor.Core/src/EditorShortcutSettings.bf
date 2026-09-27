using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.UI;

namespace Sedulous.Editor.Core;

/// One shortcut the user rebound: the action's id and the chord (an unset chord, key 0, is
/// "no shortcut", on purpose, distinct from the declaration's default).
[Serializable(1)]
class ShortcutOverrideEntry
{
	public String Id = new .() ~ delete _;
	public uint32 Key = 0;
	public uint32 Modifiers = 0;

	public EditorShortcut Chord => .((KeyCode)Key, (KeyModifiers)Modifiers);
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
			let chord = actions.Shortcut(action.Id);
			entry.Key = (uint32)chord.Key;
			entry.Modifiers = (uint32)chord.Modifiers;
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
