using System;
namespace glslang_Beef.Test
{
	class Program
	{
		private static char8* shaderCodeVertex = """
	#version 450

	vec2 positions[3] = vec2[](
	    vec2(0.0, -0.5),
	    vec2(0.5, 0.5),
	    vec2(-0.5, 0.5)
	);

	void main() {
	    gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
	}
	""";

		public static void Main()
		{
			if (glslang_initialize_process() == 0)
			{
				Runtime.FatalError("Failed to initialize glslang process.");
			}

			glslang_resource_t* resources = glslang_default_resource();

			glslang_input_t input = .()
				{
					language = .GLSLANG_SOURCE_GLSL,
					stage = .GLSLANG_STAGE_VERTEX,
					client = .GLSLANG_CLIENT_VULKAN,
					client_version = .GLSLANG_TARGET_VULKAN_1_1,
					target_language = .GLSLANG_TARGET_SPV,
					target_language_version = .GLSLANG_TARGET_SPV_1_3,
					code = shaderCodeVertex,
					default_version = 100,
					default_profile = .GLSLANG_NO_PROFILE,
					force_default_version_and_profile = 0,
					forward_compatible = 0,
					messages = .GLSLANG_MSG_DEFAULT_BIT,
					resource = resources
				};

			glslang_shader_t* shader = glslang_shader_create(&input);

			if (glslang_shader_preprocess(shader, &input) == 0)
			{
				char8* infoLog = glslang_shader_get_info_log(shader);

				char8* debugLog = glslang_shader_get_info_debug_log(shader);

				Console.WriteLine("{} {}", scope String(infoLog), scope String(debugLog));

				return;
			}

			if (glslang_shader_parse(shader, &input) == 0)
			{
				char8* infoLog = glslang_shader_get_info_log(shader);

				char8* debugLog = glslang_shader_get_info_debug_log(shader);

				Console.WriteLine("{} {}", scope String(infoLog), scope String(debugLog));

				return;
			}

			glslang_program_t* program = glslang_program_create();
			glslang_program_add_shader(program, shader);

			if (glslang_program_link(program, (.)(glslang_messages_t.GLSLANG_MSG_SPV_RULES_BIT | glslang_messages_t.GLSLANG_MSG_VULKAN_RULES_BIT)) == 0)
			{
				char8* infoLog = glslang_shader_get_info_log(shader);

				char8* debugLog = glslang_shader_get_info_debug_log(shader);

				Console.WriteLine("{} {}", scope String(infoLog), scope String(debugLog));

				return;
			}

			glslang_program_SPIRV_generate(program, input.stage);

			if (glslang_program_SPIRV_get_messages(program)  != null)
			{
				Console.WriteLine("{}", glslang_program_SPIRV_get_messages(program));
			}

			glslang_shader_delete(shader);

			glslang_program_delete(program);

			glslang_finalize_process();

			Console.Read();
		}
	}
}