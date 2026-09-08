using System;
using System.Collections;
using Sedulous.Core.Logging;

namespace Sedulous.Scene;

/// The blueprint: a topologically sorted module order, built once.
///
/// The composition COPIES each module BY VALUE and DROPS its dependency span. Dependencies
/// are build time data, consulted here and never retained, which is what makes a
/// composition self contained: a caller may build one from modules that live on the stack
/// and then go away.
class SceneComposition
{
	private List<SceneModule> mOrder = new .() ~ delete _;

	/// Builds the sorted order from `modules`.
	///
	/// A module whose dependency is not in `modules` treats it as satisfied: it is out of
	/// scope for this composition, not missing from it.
	///
	/// A dependency CYCLE is broken LOUDLY. The first remaining module is emitted anyway
	/// with an error naming it, so this always terminates and always contains every module
	/// exactly once, and the authoring mistake is visible rather than silent.
	public static SceneComposition Build(Span<SceneModule*> modules)
	{
		let composition = new SceneComposition();

		let remaining = scope List<SceneModule*>();
		let placed = scope List<SceneModule*>();
		for (let module in modules)
			remaining.Add(module);

		bool InSet(SceneModule* candidate)
		{
			for (let module in modules)
			{
				if (module == candidate)
					return true;
			}
			return false;
		}

		bool Placed(SceneModule* candidate) => placed.Contains(candidate);

		while (!remaining.IsEmpty)
		{
			// The count itself is the "nothing is ready" sentinel.
			int pick = remaining.Count;
			for (int i = 0; i < remaining.Count; i++)
			{
				var ready = true;
				for (let dependency in remaining[i].DependsOn)
				{
					if (InSet(dependency) && !Placed(dependency))
					{
						ready = false;
						break;
					}
				}
				if (ready)
				{
					pick = i;
					break;
				}
			}

			if (pick == remaining.Count)
			{
				pick = 0;
				GlobalLog(.Error,
					"SceneComposition: a module dependency CYCLE, emitting '{}' out of order. Fix the declarations.",
					remaining[0].Id);
			}

			let source = remaining[pick];
			placed.Add(source);
			// The stored copy carries the id and the two functions. The dependency span is
			// deliberately NOT carried: it would dangle exactly as a retained module pointer
			// would.
			composition.mOrder.Add(.(source.Id, source.InstallFn, source.RegisterReflectionFn));
			remaining.RemoveAt(pick);
		}

		return composition;
	}

	/// Adds every module's systems to `scene` in dependency order, then every runtime
	/// contribution.
	public void Instantiate(Scene scene)
	{
		for (var module in ref mOrder)
			module.Install(scene);
		SceneModuleContributions.Global.InstallAll(scene);
	}

	/// Registers every module's component reflection, contributions included. Idempotent,
	/// and meant to be called once at startup.
	public void RegisterReflection()
	{
		for (var module in ref mOrder)
			module.RegisterReflection();
		SceneModuleContributions.Global.RegisterAllReflection();
	}

	public int ModuleCount => mOrder.Count;
}
