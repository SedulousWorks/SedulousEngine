using ufbx_Beef;
using System.Diagnostics;
using System;

namespace ufbx_Beef_Test;

class Program
{
	static void LoadAndPrint(char8* file)
	{
		ufbx_load_opts opts = .();
		ufbx_error error = .();

		ufbx_scene* scene = ufbx_load_file(file, &opts, &error);

		if (scene != null)
		{
			Debug.WriteLine("Loaded '{0}' successfully!", StringView(file));
			Debug.WriteLine("  Nodes: {0}", scene.nodes.count);
			Debug.WriteLine("  Meshes: {0}", scene.meshes.count);
			Debug.WriteLine("  Materials: {0}", scene.materials.count);

			if (scene.meshes.count > 0)
			{
				ufbx_mesh* mesh = scene.meshes.data[0];
				Debug.WriteLine("  First mesh:");
				Debug.WriteLine("    Vertices: {0}", mesh.num_vertices);
				Debug.WriteLine("    Faces: {0}", mesh.num_faces);
				Debug.WriteLine("    Triangles: {0}", mesh.num_triangles);
			}

			ufbx_free_scene(scene);
			Debug.WriteLine("  Scene freed.");
		}
		else
		{
			Debug.WriteLine("Failed to load '{0}':", StringView(file));
			Debug.WriteLine("  Error: {0}", StringView(&error.description.data[0], (int)error.description.length));
		}
	}

	public static void Main()
	{
		Debug.WriteLine("=== ufbx-Beef Test ===");
		Debug.WriteLine("Thread safe: {0}", ufbx_is_thread_safe());

		// Test math functions
		ufbx_vec3 v = .() { x = 3.0, y = 0.0, z = 4.0 };
		ufbx_vec3 normalized = ufbx_vec3_normalize(v);
		Debug.WriteLine("Normalize ({0}, {1}, {2}) = ({3}, {4}, {5})",
			v.x, v.y, v.z, normalized.x, normalized.y, normalized.z);

		// Test coordinate axes validation
		ufbx_coordinate_axes axes = .() { right = .UFBX_COORDINATE_AXIS_POSITIVE_X, up = .UFBX_COORDINATE_AXIS_POSITIVE_Y, front = .UFBX_COORDINATE_AXIS_POSITIVE_Z };
		Debug.WriteLine("Axes valid: {0}", ufbx_coordinate_axes_valid(axes));

		// Load .obj file
		Debug.WriteLine("");
		Debug.WriteLine("--- OBJ Test ---");
		LoadAndPrint("Cube.obj");

		// Load .fbx file
		Debug.WriteLine("");
		Debug.WriteLine("--- FBX Test ---");
		LoadAndPrint("Default.fbx");

		Debug.WriteLine("");
		Debug.WriteLine("=== Test Complete ===");
	}
}
