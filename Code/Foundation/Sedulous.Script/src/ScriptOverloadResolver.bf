using System;
using System.Collections;

namespace Sedulous.Script;

/// Picks the callable for a script call at the boundary, from the table alone.
///
/// The build rule (ScriptSurfaceWalker) guarantees that no two callables on a type share a
/// script name, staticness and parameter kinds, so an EXACT match is unique. A call may
/// still need a promotion: a script's `1` is Int and `Lerp` takes floats. The resolution:
///  - a candidate has the script name and staticness, accepts the count (at least its
///    required parameters, at most all of them), and every argument Matches its slot;
///  - among those, the fewest promotions wins;
///  - a tie is AMBIGUOUS and the call fails, naming the candidates, rather than guessing.
/// With one number type, `Abs(1)` is exact on Abs(int) and a promotion on Abs(float), so
/// the integer one wins; `Abs(1.5)` matches only Abs(float).
static class ScriptOverloadResolver
{
	public static ScriptMethodInfo Resolve(ScriptTypeInfo type, StringView scriptName, bool isStatic,
		Span<ScriptValue> args, String outError)
	{
		ScriptMethodInfo best = null;
		int bestCost = int.MaxValue;
		bool tie = false;
		bool anyNamed = false;

		for (let m in type.Methods)
		{
			if ((m.ScriptName != scriptName) || (m.IsStatic != isStatic))
				continue;
			anyNamed = true;
			if ((args.Length < m.RequiredParams) || (args.Length > m.Params.Count))
				continue;

			int cost = 0;
			bool ok = true;
			for (int i = 0; i < args.Length; i++)
			{
				let p = m.Params[i];
				if (!args[i].Matches(p.Kind, p.TypeName, let exact))
				{
					ok = false;
					break;
				}
				if (!exact)
					cost++;
			}
			if (!ok)
				continue;

			if (cost < bestCost)
			{
				best = m;
				bestCost = cost;
				tie = false;
			}
			else if (cost == bestCost)
			{
				tie = true;
			}
		}

		if (best == null)
		{
			if (!anyNamed)
				outError.AppendF("{} has no {}{}", type.FullName, isStatic ? "static " : "", scriptName);
			else
				outError.AppendF("no {} on {} takes these {} arguments", scriptName, type.FullName, args.Length);
			return null;
		}
		if (tie)
		{
			outError.AppendF("{} on {} is ambiguous for these arguments; more than one overload fits equally", scriptName, type.FullName);
			return null;
		}
		return best;
	}
}
