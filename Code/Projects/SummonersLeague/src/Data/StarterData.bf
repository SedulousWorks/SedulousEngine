namespace SummonersLeague.Data;

/// Populates the GameDatabase with initial monster, ability, and item definitions.
/// This is the code-defined data layer — will be replaced with serialized data
/// once the roster is finalized.
static class StarterData
{
	public static void Populate(GameDatabase db)
	{
		RegisterAbilities(db);
		RegisterMonsters(db);
		RegisterItems(db);
	}

	private static void RegisterAbilities(GameDatabase db)
	{
		// --- Basic attacks (one per element) ---
		db.RegisterAbility(new .()
		{
			Id = "basic_fire", Name = "Ember Strike",
			Element = .Fire, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic fire attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_earth", Name = "Vine Lash",
			Element = .Earth, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic earth attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_water", Name = "Aqua Shot",
			Element = .Water, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic water attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_wind", Name = "Gust Slash",
			Element = .Wind, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic wind attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_electric", Name = "Spark Jolt",
			Element = .Electric, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic electric attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_dark", Name = "Shadow Swipe",
			Element = .Dark, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic dark attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_light", Name = "Holy Strike",
			Element = .Light, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic light attack."
		});

		db.RegisterAbility(new .()
		{
			Id = "basic_neutral", Name = "Tackle",
			Element = .Neutral, Target = .SingleEnemy,
			DamageMultiplier = 1.0f,
			Description = "A basic physical attack."
		});

		// --- Special abilities ---
		db.RegisterAbility(new .()
		{
			Id = "fireball", Name = "Fireball",
			Element = .Fire, Target = .SingleEnemy,
			DamageMultiplier = 2.0f, Cooldown = 3,
			StatusEffects = new .(.() { Effect = .Burn, Duration = 2, Chance = 0.5f, Value = 0.05f }),
			UnlockLevel = 5,
			Description = "Hurls a fireball. May inflict Burn."
		});

		db.RegisterAbility(new .()
		{
			Id = "inferno", Name = "Inferno",
			Element = .Fire, Target = .AllEnemies,
			DamageMultiplier = 1.5f, Cooldown = 4,
			StatusEffects = new .(.() { Effect = .Burn, Duration = 2, Chance = 0.3f, Value = 0.05f }),
			UnlockLevel = 10,
			Description = "Engulfs all enemies in flames."
		});

		db.RegisterAbility(new .()
		{
			Id = "thorn_wall", Name = "Thorn Wall",
			Element = .Earth, Target = .AllAllies,
			Cooldown = 4,
			StatusEffects = new .(.() { Effect = .Shield, Duration = 2, Chance = 1.0f, Value = 0.2f }),
			UnlockLevel = 5,
			Description = "Shields all allies with thorny vines."
		});

		db.RegisterAbility(new .()
		{
			Id = "bloom_heal", Name = "Bloom",
			Element = .Earth, Target = .SingleAlly,
			HealMultiplier = 2.0f, Cooldown = 3,
			UnlockLevel = 8,
			Description = "Heals an ally with restorative energy."
		});

		db.RegisterAbility(new .()
		{
			Id = "frost_bite", Name = "Frost Bite",
			Element = .Water, Target = .SingleEnemy,
			DamageMultiplier = 1.8f, Cooldown = 3,
			StatusEffects = new .(.() { Effect = .Freeze, Duration = 1, Chance = 0.4f }),
			UnlockLevel = 5,
			Description = "Bites with icy fangs. May freeze the target."
		});

		db.RegisterAbility(new .()
		{
			Id = "thunder_bolt", Name = "Thunder Bolt",
			Element = .Electric, Target = .SingleEnemy,
			DamageMultiplier = 2.2f, Cooldown = 3,
			StatusEffects = new .(.() { Effect = .Stun, Duration = 1, Chance = 0.3f }),
			UnlockLevel = 5,
			Description = "Strikes with lightning. May stun the target."
		});

		db.RegisterAbility(new .()
		{
			Id = "shadow_curse", Name = "Shadow Curse",
			Element = .Dark, Target = .SingleEnemy,
			DamageMultiplier = 1.5f, Cooldown = 3,
			StatusEffects = new .(.() { Effect = .DefBreak, Duration = 2, Chance = 0.7f, Value = 0.3f }),
			UnlockLevel = 5,
			Description = "Curses the target, reducing their defense."
		});

		db.RegisterAbility(new .()
		{
			Id = "gale_force", Name = "Gale Force",
			Element = .Wind, Target = .AllEnemies,
			DamageMultiplier = 1.3f, Cooldown = 4,
			UnlockLevel = 8,
			Description = "Blasts all enemies with a powerful gust."
		});

		db.RegisterAbility(new .()
		{
			Id = "divine_light", Name = "Divine Light",
			Element = .Light, Target = .AllAllies,
			HealMultiplier = 1.5f, Cooldown = 4,
			StatusEffects = new .(.() { Effect = .Immunity, Duration = 1, Chance = 1.0f }),
			UnlockLevel = 10,
			Description = "Heals all allies and grants brief immunity."
		});
	}

	private static void RegisterMonsters(GameDatabase db)
	{
		// --- Fire starters ---
		db.RegisterMonster(new .()
		{
			Id = "dragon_spark", Name = "Dragon Spark",
			Element = .Fire, Rarity = .Rare,
			Stats = .() { HP = 32, ATK = 18, DEF = 12, SPD = 14 },
			Abilities = new .(db.GetAbility("basic_fire"), db.GetAbility("fireball")),
			EvolvesInto = "dragon_fire",
			ModelAsset = "Dragon Spark",
			Description = "A young dragon crackling with sparks."
		});

		db.RegisterMonster(new .()
		{
			Id = "dragon_fire", Name = "Dragon Fire",
			Element = .Fire, Rarity = .Epic,
			Stats = .() { HP = 42, ATK = 25, DEF = 16, SPD = 16 },
			Abilities = new .(db.GetAbility("basic_fire"), db.GetAbility("fireball"), db.GetAbility("inferno")),
			EvolvesInto = "dragon_inferno",
			ModelAsset = "Dragon Fire",
			Description = "A fierce dragon wreathed in flame."
		});

		db.RegisterMonster(new .()
		{
			Id = "dragon_inferno", Name = "Dragon Inferno",
			Element = .Fire, Rarity = .Legendary,
			Stats = .() { HP = 55, ATK = 35, DEF = 20, SPD = 18 },
			Abilities = new .(db.GetAbility("basic_fire"), db.GetAbility("fireball"), db.GetAbility("inferno")),
			ModelAsset = "Dragon Inferno",
			Description = "An ancient dragon of devastating power."
		});

		// --- Earth starters ---
		db.RegisterMonster(new .()
		{
			Id = "seed", Name = "Seed",
			Element = .Earth, Rarity = .Common,
			Stats = .() { HP = 25, ATK = 10, DEF = 14, SPD = 10 },
			Abilities = new .(db.GetAbility("basic_earth"), db.GetAbility("thorn_wall")),
			EvolvesInto = "sprout",
			ModelAsset = "Seed",
			Description = "A tiny seed brimming with life energy."
		});

		db.RegisterMonster(new .()
		{
			Id = "sprout", Name = "Sprout",
			Element = .Earth, Rarity = .Uncommon,
			Stats = .() { HP = 35, ATK = 14, DEF = 18, SPD = 12 },
			Abilities = new .(db.GetAbility("basic_earth"), db.GetAbility("thorn_wall"), db.GetAbility("bloom_heal")),
			EvolvesInto = "bloom",
			ModelAsset = "Sprout",
			Description = "A growing sprout reaching for the sun."
		});

		db.RegisterMonster(new .()
		{
			Id = "bloom", Name = "Bloom",
			Element = .Earth, Rarity = .Rare,
			Stats = .() { HP = 48, ATK = 18, DEF = 24, SPD = 14 },
			Abilities = new .(db.GetAbility("basic_earth"), db.GetAbility("thorn_wall"), db.GetAbility("bloom_heal")),
			ModelAsset = "Bloom",
			Description = "A fully bloomed flower with powerful defenses."
		});

		// --- Water ---
		db.RegisterMonster(new .()
		{
			Id = "dragon_water", Name = "Dragon Water",
			Element = .Water, Rarity = .Rare,
			Stats = .() { HP = 35, ATK = 16, DEF = 14, SPD = 15 },
			Abilities = new .(db.GetAbility("basic_water"), db.GetAbility("frost_bite")),
			EvolvesInto = "dragon_ice",
			ModelAsset = "Dragon Water",
			Description = "A serpentine dragon born from glacial waters."
		});

		// --- Electric ---
		db.RegisterMonster(new .()
		{
			Id = "cat_meow", Name = "Cat Meow",
			Element = .Electric, Rarity = .Common,
			Stats = .() { HP = 22, ATK = 12, DEF = 10, SPD = 18 },
			Abilities = new .(db.GetAbility("basic_electric"), db.GetAbility("thunder_bolt")),
			EvolvesInto = "cat_bolt",
			ModelAsset = "Cat Meow",
			Description = "A playful kitten with a shocking personality."
		});

		// --- Dark ---
		db.RegisterMonster(new .()
		{
			Id = "shade", Name = "Shade",
			Element = .Dark, Rarity = .Common,
			Stats = .() { HP = 23, ATK = 14, DEF = 10, SPD = 16 },
			Abilities = new .(db.GetAbility("basic_dark"), db.GetAbility("shadow_curse")),
			EvolvesInto = "shadow",
			ModelAsset = "Shade",
			Description = "A wisp of darkness that flickers at the edge of sight."
		});

		// --- Wind ---
		db.RegisterMonster(new .()
		{
			Id = "bat", Name = "Bat",
			Element = .Wind, Rarity = .Common,
			Stats = .() { HP = 20, ATK = 13, DEF = 9, SPD = 20 },
			Abilities = new .(db.GetAbility("basic_wind"), db.GetAbility("gale_force")),
			EvolvesInto = "vampire_bat",
			ModelAsset = "Bat",
			Description = "A swift nocturnal flyer."
		});

		// --- Light ---
		db.RegisterMonster(new .()
		{
			Id = "angel", Name = "Angel",
			Element = .Light, Rarity = .Epic,
			Stats = .() { HP = 38, ATK = 15, DEF = 18, SPD = 16 },
			Abilities = new .(db.GetAbility("basic_light"), db.GetAbility("divine_light")),
			EvolvesInto = "angel_mage",
			ModelAsset = "Angel",
			Description = "A radiant being of pure light."
		});

		// --- Neutral ---
		db.RegisterMonster(new .()
		{
			Id = "wolf_pup", Name = "Wolf Pup",
			Element = .Neutral, Rarity = .Common,
			Stats = .() { HP = 24, ATK = 13, DEF = 11, SPD = 15 },
			Abilities = new .(db.GetAbility("basic_neutral")),
			EvolvesInto = "wolf",
			ModelAsset = "Wolf Pup",
			Description = "A young wolf, eager to prove itself."
		});
	}

	private static void RegisterItems(GameDatabase db)
	{
		db.RegisterItem(new .()
		{
			Id = "iron_fang", Name = "Iron Fang",
			Category = .Power,
			AtkBonus = 0.15f,
			Description = "+15% ATK"
		});

		db.RegisterItem(new .()
		{
			Id = "blood_shard", Name = "Blood Shard",
			Category = .Power,
			DamageBonus = 0.20f, HpCostPerAttack = 0.05f,
			Description = "+20% damage dealt, lose 5% HP per attack."
		});

		db.RegisterItem(new .()
		{
			Id = "speed_charm", Name = "Speed Charm",
			Category = .Agility,
			SpdBonus = 0.15f,
			Description = "+15% SPD"
		});

		db.RegisterItem(new .()
		{
			Id = "evasion_cloak", Name = "Evasion Cloak",
			Category = .Agility,
			DodgeChance = 0.10f,
			Description = "+10% dodge chance."
		});

		db.RegisterItem(new .()
		{
			Id = "focus_lens", Name = "Focus Lens",
			Category = .Accuracy,
			HitRateBonus = 0.15f,
			Description = "+15% hit rate."
		});

		db.RegisterItem(new .()
		{
			Id = "precision_ring", Name = "Precision Ring",
			Category = .Accuracy,
			DebuffLandRate = 0.20f,
			Description = "Debuffs have +20% application rate."
		});

		db.RegisterItem(new .()
		{
			Id = "ward_stone", Name = "Ward Stone",
			Category = .Resistance,
			DebuffResist = 0.15f,
			Description = "+15% debuff resist."
		});

		db.RegisterItem(new .()
		{
			Id = "last_stand_amulet", Name = "Last Stand Amulet",
			Category = .Resistance,
			SurviveFatalHit = true,
			Description = "Survive a fatal hit with 1 HP (once per battle)."
		});

		db.RegisterItem(new .()
		{
			Id = "mending_root", Name = "Mending Root",
			Category = .Resistance,
			HealPerTurn = 0.05f,
			Description = "Heal 5% HP at end of each turn."
		});
	}
}
