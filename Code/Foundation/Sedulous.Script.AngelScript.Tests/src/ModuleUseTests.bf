using System;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// What keeps a module's code in use: an instance of one of its classes, a coroutine started in
/// it, a delegate to one of its functions. Nothing else does, so it can go.
static class ModuleUseTests
{
	[Test]
	public static void AModuleIsInUseWhileAnInstanceOrACoroutineRunsItsCode()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);
		ClearAndDeleteItems!(vm.Problems);
		Test.Assert(vm.Compile("m", "m.as", "class Tenant { int n = 1; }\nvoid sleeper() { wait(10.0); }\nvoid begin() { startCoroutine(sleeper); }\n"), vm.Problems.IsEmpty ? "" : vm.Problems[0]);
		Test.Assert(!vm.ModuleInUse("m"), "nothing of it runs");
		Test.Assert(!vm.ModuleInUse("none"), "no such module");

		let thing = vm.Instantiate("m", "Tenant");
		Test.Assert(thing != null);
		Test.Assert(vm.ModuleInUse("m"), "an instance of its class");
		vm.Release(thing);
		Test.Assert(!vm.ModuleInUse("m"));

		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("m", "void begin()", default, ref r));
		Test.Assert(vm.ModuleInUse("m"), "a coroutine started in it");
		vm.AdvanceCoroutines(11.0);
		Test.Assert(vm.CoroutineCount == 0);
		Test.Assert(!vm.ModuleInUse("m"));
	}
}
