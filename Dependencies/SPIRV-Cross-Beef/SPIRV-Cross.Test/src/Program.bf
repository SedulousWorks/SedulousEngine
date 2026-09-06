using System;
using SPIRV_Cross;
using System.IO;
using System.Collections;
namespace SPIRV_Cross.Test
{
	using static SPIRV_Cross.SPIRV;

	class Program
	{
		static bool g_fail_on_error = true;

		private static mixin SPVC_CHECKED_CALL<T>(spvc_result result, T retVal)
		{
			if (result != .SPVC_SUCCESS)
			{
				Console.WriteLine($"Failed: {result}");
				return retVal;
			}
		}

		private static mixin SPVC_CHECKED_CALL_NEGATIVE(delegate spvc_result() result)
		{
			g_fail_on_error = false;
			if (result() == .SPVC_SUCCESS)
			{
				Console.WriteLine($"Failed: {result}");
				return 1;
			}
			g_fail_on_error = true;
		}

		public static void error_callback(void* userdata, char8* error)
		{
			(void)userdata;
			if (g_fail_on_error)
			{
				Console.WriteLine("Error: {0}\n", scope String(error));
				Runtime.FatalError();
			}
			else
				Console.WriteLine("Expected error hit: {0}\n", scope String(error));
		}

		private static void dump_resource_list(spvc_compiler compiler, spvc_resources resources, spvc_resource_type type, in StringView tag)
		{
			spvc_reflected_resource* list = null;
			uint count = 0;
			SPVC_CHECKED_CALL!(spvc_resources_get_resource_list_for_type(resources, type, (.)&list, &count), void());
			Console.WriteLine(tag);
			for (uint i = 0; i < count; i++)
			{
				Console.WriteLine("ID:{0}, BaseTypeID: {1}, TypeID: {2}, Name: {3}\n", list[i].id, list[i].base_type_id, list[i].type_id,
					scope String(list[i].name));
				Console.WriteLine("  Set: {0}, Binding: {1}\n",
					spvc_compiler_get_decoration(compiler, list[i].id, .SpvDecorationDescriptorSet),
					spvc_compiler_get_decoration(compiler, list[i].id, .SpvDecorationBinding));
			}
		}

		private static void dump_resources(spvc_compiler compiler, spvc_resources resources)
		{
			dump_resource_list(compiler, resources, .UniformBuffer, "UBO");
			dump_resource_list(compiler, resources, .StorageBuffer, "SSBO");
			dump_resource_list(compiler, resources, .PushConstant, "Push");
			dump_resource_list(compiler, resources, .SeparateSamplers, "Samplers");
			dump_resource_list(compiler, resources, .SeparateImage, "Image");
			dump_resource_list(compiler, resources, .SampledImage, "Combined image samplers");
			dump_resource_list(compiler, resources, .StageInput, "Stage input");
			dump_resource_list(compiler, resources, .StageOutput, "Stage output");
			dump_resource_list(compiler, resources, .StorageImage, "Storage image");
			dump_resource_list(compiler, resources, .SubpassInput, "Subpass input");
		}

		private static void compile(spvc_compiler compiler, in char8* tag)
		{
			char8* result = null;
			SPVC_CHECKED_CALL!(spvc_compiler_compile(compiler, (.)&result), void());
			Console.WriteLine("{0}\n=======\n", scope String(tag));
			Console.WriteLine("{0}\n=======\n", scope String(result));
		}

		public static int Main(String[] args)
		{
			char8* rev = null;

			spvc_context context = .Null;
			spvc_parsed_ir ir = .Null;
			spvc_compiler compiler_glsl = .Null;
			spvc_compiler compiler_hlsl = .Null;
			spvc_compiler compiler_msl = .Null;
			spvc_compiler compiler_cpp = .Null;
			spvc_compiler compiler_json = .Null;
			spvc_compiler compiler_none = .Null;
			spvc_compiler_options options = .Null;
			spvc_resources resources = .Null;
			SpvId* buffer = null;
			uint word_count = 0;

			rev = spvc_get_commit_revision_and_timestamp();
			if (rev == null || *rev == '\0')
				return 1;

			Console.WriteLine($"Revision: {scope String(rev)}");

			if (args.Count != 4)
				return 1;

			var data = File.ReadAll(args[0], .. scope List<uint8>());
			word_count = (.)data.Count / sizeof(SpvId);
			buffer = (.)data.Ptr;

			uint32 abi_major = 0, abi_minor = 0, abi_patch = 0;
			spvc_get_version(&abi_major, &abi_minor, &abi_patch);

			var result = UInt32.Parse(args[1]);
			if (result case .Err)
			{
				return 1;
			}

			if (abi_major != result.Value)
			{
				Console.WriteLine("VERSION_MAJOR mismatch!\n");
				return 1;
			}

			result = UInt32.Parse(args[2]);
			if (result case .Err)
			{
				return 1;
			}
			if (abi_minor != result.Value)
			{
				Console.WriteLine("VERSION_MAJOR mismatch!\n");
				return 1;
			}

			result = UInt32.Parse(args[3]);
			if (result case .Err)
			{
				return 1;
			}
			if (abi_patch != result.Value)
			{
				Console.WriteLine("VERSION_MAJOR mismatch!\n");
				return 1;
			}

			SPVC_CHECKED_CALL!(spvc_context_create(&context), 1);

			function void(void* userdata, char8* error) errorCb = => error_callback;
			spvc_error_callback cb = .((int)(void*)errorCb);

			spvc_context_set_error_callback(context, cb, null);
			SPVC_CHECKED_CALL!(spvc_context_parse_spirv(context, buffer, word_count, &ir), 1);
			SPVC_CHECKED_CALL!(spvc_context_create_compiler(context, .Glsl, ir, .Copy, &compiler_glsl), 1);
			SPVC_CHECKED_CALL!(spvc_context_create_compiler(context, .Hlsl, ir, .Copy, &compiler_hlsl), 1);
			SPVC_CHECKED_CALL!(spvc_context_create_compiler(context, .Msl, ir, .Copy, &compiler_msl), 1);
			SPVC_CHECKED_CALL!(spvc_context_create_compiler(context, .Cpp, ir, .Copy, &compiler_cpp), 1);
			SPVC_CHECKED_CALL!(spvc_context_create_compiler(context, .Json, ir, .Copy, &compiler_json), 1);
			SPVC_CHECKED_CALL!(spvc_context_create_compiler(context, .None, ir, .TakeOwnership, &compiler_none), 1);

			SPVC_CHECKED_CALL!(spvc_compiler_create_compiler_options(compiler_none, &options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_install_compiler_options(compiler_none, options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_create_compiler_options(compiler_json, &options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_install_compiler_options(compiler_json, options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_create_compiler_options(compiler_cpp, &options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_install_compiler_options(compiler_cpp, options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_create_compiler_options(compiler_msl, &options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_install_compiler_options(compiler_msl, options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_create_compiler_options(compiler_hlsl, &options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_options_set_uint(options, .HlslShaderModel, 50), 1);

			delegate spvc_result() dlg = scope () => spvc_compiler_options_set_uint(options, .MslPlatform, 1);
			SPVC_CHECKED_CALL_NEGATIVE!(dlg);
			SPVC_CHECKED_CALL!(spvc_compiler_install_compiler_options(compiler_hlsl, options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_create_compiler_options(compiler_glsl, &options), 1);
			SPVC_CHECKED_CALL!(spvc_compiler_install_compiler_options(compiler_glsl, options), 1);

			const uint32 NUM_EXTS = 2;
			char8*[NUM_EXTS] expected_exts = .(
				"EXT_first",
				"EXT_second"
				);

			uint32 ext_idx = 0;
			while (ext_idx < NUM_EXTS)
			{
				SPVC_CHECKED_CALL!(spvc_compiler_require_extension(compiler_glsl, expected_exts[ext_idx]), 1);
				ext_idx += 1;
			}

			SPVC_CHECKED_CALL!(spvc_compiler_create_shader_resources(compiler_none, &resources), 1);
			dump_resources(compiler_none, resources);
			compile(compiler_glsl, "GLSL");
			compile(compiler_hlsl, "HLSL");
			compile(compiler_msl, "MSL");
			compile(compiler_json, "JSON");
			compile(compiler_cpp, "CPP");

			uint num_exts = spvc_compiler_get_num_required_extensions(compiler_glsl);
			if (num_exts != NUM_EXTS)
			{
				Console.WriteLine("num_exts mismatch!");
				return 1;
			}

			ext_idx = 0;
			while (ext_idx < num_exts)
			{
				char8* ext = spvc_compiler_get_required_extension(compiler_glsl, ext_idx);
				if (!String.Equals(ext, expected_exts[ext_idx]))
				{
					Console.WriteLine(scope $"extension mismatch ({scope String(ext)} != {scope String(expected_exts[ext_idx])})!");
					return 1;
				}
				ext_idx += 1;
			}

			spvc_context_destroy(context);

			Console.Read();
			return 0;
		}
	}
}