using System;
using AngelScript;

namespace Sedulous.Script.AngelScript.Tests;

/// The shim links and the engine runs: compile a function and call it, with a message
/// callback that sees a compile error.
static class EngineSmokeTests
{
	private static int sMessages = 0;

	private static void OnMessage(char8* section, int32 row, int32 col, int32 type, char8* message, void* user)
	{
		sMessages++;
		Console.WriteLine("as: {} ({},{}) [{}] {}", StringView(section), row, col, type, StringView(message));
	}

	[Test]
	public static void AScriptCompilesAndRuns()
	{
		let engine = AS.asc_engine_create();
		Test.Assert(engine != null);
		defer AS.asc_engine_release(engine);
		AS.asc_engine_set_message_callback(engine, => OnMessage, null);
		AS.asc_engine_register_std_string(engine);
		AS.asc_engine_register_script_array(engine, 1);

		let module = AS.asc_engine_get_module(engine, "smoke", AS.asGM_ALWAYS_CREATE);
		let source = "int add(int a, int b) { return a + b; }\nstring greet(const string &in who) { return \"hi \" + who; }";
		Test.Assert(AS.asc_module_add_script_section(module, "smoke.as", source.CStr(), (uint)source.Length) >= 0);
		Test.Assert(AS.asc_module_build(module) >= 0, "the script built");

		let add = AS.asc_module_get_function_by_decl(module, "int add(int, int)");
		Test.Assert(add != null);
		let ctx = AS.asc_engine_create_context(engine);
		defer AS.asc_context_release(ctx);
		Test.Assert(AS.asc_context_prepare(ctx, add) >= 0);
		AS.asc_context_set_arg_dword(ctx, 0, 40);
		AS.asc_context_set_arg_dword(ctx, 1, 2);
		Test.Assert(AS.asc_context_execute(ctx) == AS.asEXECUTION_FINISHED);
		Test.Assert(AS.asc_context_get_return_dword(ctx) == 42);

		// A string in and out, through the add-on's std::string.
		let greet = AS.asc_module_get_function_by_decl(module, "string greet(const string &in)");
		Test.Assert(greet != null);
		let who = new uint8[AS.asc_string_size()]*;
		defer delete who;
		AS.asc_string_construct(who, "beef", 4);
		defer AS.asc_string_destruct(who);
		Test.Assert(AS.asc_context_prepare(ctx, greet) >= 0);
		AS.asc_context_set_arg_object(ctx, 0, who);
		Test.Assert(AS.asc_context_execute(ctx) == AS.asEXECUTION_FINISHED);
		uint length = 0;
		let data = AS.asc_string_data(AS.asc_context_get_return_object(ctx), &length);
		Test.Assert(StringView(data, (int)length) == "hi beef");

		// A broken script reports through the callback and fails the build.
		let bad = AS.asc_engine_get_module(engine, "bad", AS.asGM_ALWAYS_CREATE);
		let broken = "int f( { }";
		AS.asc_module_add_script_section(bad, "bad.as", broken.CStr(), (uint)broken.Length);
		let before = sMessages;
		Test.Assert(AS.asc_module_build(bad) < 0);
		Test.Assert(sMessages > before, "the compiler said why");
	}
}
