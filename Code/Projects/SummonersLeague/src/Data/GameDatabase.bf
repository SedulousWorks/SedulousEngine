namespace SummonersLeague.Data;

using System;
using System.Collections;

/// Central registry of all monster, ability, and item definitions.
/// Populated at startup from code-defined data. Provides lookup by id.
class GameDatabase
{
	private Dictionary<StringView, MonsterDef> mMonsters = new .() ~ delete _;
	private Dictionary<StringView, AbilityDef> mAbilities = new .() ~ delete _;
	private Dictionary<StringView, ItemDef> mItems = new .() ~ delete _;

	// Owned definition objects (deleted on shutdown)
	private List<MonsterDef> mOwnedMonsters = new .() ~ DeleteContainerAndItems!(_);
	private List<AbilityDef> mOwnedAbilities = new .() ~ DeleteContainerAndItems!(_);
	private List<ItemDef> mOwnedItems = new .() ~ DeleteContainerAndItems!(_);

	/// Register a monster definition. The database takes ownership.
	public void RegisterMonster(MonsterDef def)
	{
		mOwnedMonsters.Add(def);
		mMonsters[def.Id] = def;
	}

	/// Register an ability definition. The database takes ownership.
	public void RegisterAbility(AbilityDef def)
	{
		mOwnedAbilities.Add(def);
		mAbilities[def.Id] = def;
	}

	/// Register an item definition. The database takes ownership.
	public void RegisterItem(ItemDef def)
	{
		mOwnedItems.Add(def);
		mItems[def.Id] = def;
	}

	/// Look up a monster by id. Returns null if not found.
	public MonsterDef GetMonster(StringView id)
	{
		if (mMonsters.TryGetValue(id, let def))
			return def;
		return null;
	}

	/// Look up an ability by id. Returns null if not found.
	public AbilityDef GetAbility(StringView id)
	{
		if (mAbilities.TryGetValue(id, let def))
			return def;
		return null;
	}

	/// Look up an item by id. Returns null if not found.
	public ItemDef GetItem(StringView id)
	{
		if (mItems.TryGetValue(id, let def))
			return def;
		return null;
	}

	/// Get the evolution target for a monster. Returns null if final form.
	public MonsterDef GetEvolution(MonsterDef monster)
	{
		if (monster.EvolvesInto.IsEmpty)
			return null;
		return GetMonster(monster.EvolvesInto);
	}

	/// Get the full evolution chain starting from a monster.
	/// Returns a list including the input monster and all subsequent forms.
	public void GetEvolutionChain(MonsterDef monster, List<MonsterDef> chain)
	{
		chain.Clear();
		var current = monster;
		while (current != null)
		{
			chain.Add(current);
			current = GetEvolution(current);
		}
	}

	/// All registered monsters.
	public List<MonsterDef> AllMonsters => mOwnedMonsters;

	/// All registered abilities.
	public List<AbilityDef> AllAbilities => mOwnedAbilities;

	/// All registered items.
	public List<ItemDef> AllItems => mOwnedItems;
}
