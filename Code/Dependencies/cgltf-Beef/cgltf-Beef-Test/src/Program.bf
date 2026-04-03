using cgltf_Beef;
using System.Diagnostics;

namespace cgltf_Beef_Test;

class Program
{
	public static void Main()
	{
		cgltf_options options = .();

		cgltf_data* data = null;

		char8* file = "Box.gltf";

		cgltf_result result = cgltf_parse_file(&options, file, &data);

		if (result == .cgltf_result_success)
			result = cgltf_load_buffers(&options, data, file);

		if (result == .cgltf_result_success)
			result = cgltf_validate(data);

		Debug.WriteLine("Result: {0}", result);

		if (result == .cgltf_result_success)
		{
			Debug.WriteLine("Type: {0}", data.file_type);
			Debug.WriteLine("Meshes: {0}", data.meshes_count);
		}

		cgltf_free(data);
	}
}