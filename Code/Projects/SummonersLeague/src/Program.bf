namespace SummonersLeague;

using System;
using SummonersLeague.Data;
using System.Collections;

class Program
{
	static void Main()
	{
		let db = scope GameDatabase();
		StarterData.Populate(db);

		// Verify monsters loaded
		Console.WriteLine("=== Summoner's League - Data Test ===\n");

		Console.WriteLine(scope $"Monsters: {db.AllMonsters.Count}");
		Console.WriteLine(scope $"Abilities: {db.AllAbilities.Count}");
		Console.WriteLine(scope $"Items: {db.AllItems.Count}");
		Console.WriteLine();

		// Print all monsters
		Console.WriteLine("--- Monsters ---");
		for (let monster in db.AllMonsters)
		{
			let evolveStr = monster.EvolvesInto.IsEmpty ? "final form" : scope $"-> {monster.EvolvesInto}";
			Console.WriteLine(scope $"  {monster.Name} [{monster.Element}] ({monster.Rarity} {monster.Rarity.Stars}*) HP:{monster.Stats.HP} ATK:{monster.Stats.ATK} DEF:{monster.Stats.DEF} SPD:{monster.Stats.SPD} | {evolveStr}");
		}
		Console.WriteLine();

		// Test evolution chain
		Console.WriteLine("--- Evolution Chain: Dragon Spark ---");
		let chain = scope List<MonsterDef>();
		if (let spark = db.GetMonster("dragon_spark"))
		{
			db.GetEvolutionChain(spark, chain);
			for (let i < chain.Count)
			{
				let m = chain[i];
				if (i > 0) Console.Write(" -> ");
				Console.Write(scope $"{m.Name} ({m.Rarity})");
			}
			Console.WriteLine();
		}
		Console.WriteLine();

		// Test type chart
		Console.WriteLine("--- Type Chart Test ---");
		Console.WriteLine(scope $"  Fire vs Earth: {TypeChart.GetMultiplier(.Fire, .Earth)}* (should be {TypeChart.SuperEffective})");
		Console.WriteLine(scope $"  Fire vs Wind:  {TypeChart.GetMultiplier(.Fire, .Wind)}* (should be {TypeChart.Resisted})");
		Console.WriteLine(scope $"  Dark vs Light: {TypeChart.GetMultiplier(.Dark, .Light)}* (should be {TypeChart.SuperEffective})");
		Console.WriteLine(scope $"  Fire vs Fire:  {TypeChart.GetMultiplier(.Fire, .Fire)}* (should be {TypeChart.Normal})");
		Console.WriteLine(scope $"  Neutral vs Fire: {TypeChart.GetMultiplier(.Neutral, .Fire)}* (should be {TypeChart.Normal})");
		Console.WriteLine();

		// Test dual type
		Console.WriteLine("--- Dual Type Test (Dragon Nightfall: Dark/Fire) ---");
		Console.WriteLine(scope $"  Wind vs Dark/Fire: {TypeChart.GetDualTypeMultiplier(.Wind, .Dark, .Fire)}* (should be 1.5 - SE vs Fire, neutral vs Dark)");
		Console.WriteLine(scope $"  Water vs Dark/Fire: {TypeChart.GetDualTypeMultiplier(.Water, .Dark, .Fire)}* (should be 1.0 - neutral vs both)");

		Console.Read();
	}
}
