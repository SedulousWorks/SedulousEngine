using System;
namespace ufbx_Beef;

typealias ufbx_real = double;

static{
	public const uint32 UFBX_NO_INDEX = ~(uint32)0;
}
	// -- Basic types

	[CRepr]
	public struct ufbx_string
	{
		public char8* data;
		public uint length;
	}

	[CRepr]
	public struct ufbx_blob
	{
		public void* data;
		public uint size;
	}

	[CRepr]
	public struct ufbx_vec2
	{
		public ufbx_real x, y;
	}

	[CRepr]
	public struct ufbx_vec3
	{
		public ufbx_real x, y, z;
	}

	[CRepr]
	public struct ufbx_vec4
	{
		public ufbx_real x, y, z, w;
	}

	[CRepr]
	public struct ufbx_quat
	{
		public ufbx_real x, y, z, w;
	}

	public enum ufbx_rotation_order : int32
	{
		UFBX_ROTATION_ORDER_XYZ,
		UFBX_ROTATION_ORDER_XZY,
		UFBX_ROTATION_ORDER_YZX,
		UFBX_ROTATION_ORDER_YXZ,
		UFBX_ROTATION_ORDER_ZXY,
		UFBX_ROTATION_ORDER_ZYX,
		UFBX_ROTATION_ORDER_SPHERIC,
	}

	[CRepr]
	public struct ufbx_transform
	{
		public ufbx_vec3 translation;
		public ufbx_quat rotation;
		public ufbx_vec3 scale;
	}

	[CRepr]
	public struct ufbx_matrix
	{
		public ufbx_real m00, m10, m20;
		public ufbx_real m01, m11, m21;
		public ufbx_real m02, m12, m22;
		public ufbx_real m03, m13, m23;
	}

	[CRepr]
	public struct ufbx_void_list
	{
		public void* data;
		public uint count;
	}

	// Basic list types

	[CRepr]
	public struct ufbx_bool_list
	{
		public bool* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_uint32_list
	{
		public uint32* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_real_list
	{
		public ufbx_real* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_vec2_list
	{
		public ufbx_vec2* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_vec3_list
	{
		public ufbx_vec3* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_vec4_list
	{
		public ufbx_vec4* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_string_list
	{
		public ufbx_string* data;
		public uint count;
	}

	// -- Document object model

	public enum ufbx_dom_value_type : int32
	{
		UFBX_DOM_VALUE_NUMBER,
		UFBX_DOM_VALUE_STRING,
		UFBX_DOM_VALUE_BLOB,
		UFBX_DOM_VALUE_ARRAY_I32,
		UFBX_DOM_VALUE_ARRAY_I64,
		UFBX_DOM_VALUE_ARRAY_F32,
		UFBX_DOM_VALUE_ARRAY_F64,
		UFBX_DOM_VALUE_ARRAY_BLOB,
		UFBX_DOM_VALUE_ARRAY_IGNORED,
	}

	[CRepr]
	public struct ufbx_int32_list
	{
		public int32* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_int64_list
	{
		public int64* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_float_list
	{
		public float* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_double_list
	{
		public double* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_blob_list
	{
		public ufbx_blob* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_dom_value
	{
		public ufbx_dom_value_type type;
		public ufbx_string value_str;
		public ufbx_blob value_blob;
		public int64 value_int;
		public double value_float;
	}

	[CRepr]
	public struct ufbx_dom_node_list
	{
		public ufbx_dom_node** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_dom_value_list
	{
		public ufbx_dom_value* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_dom_node
	{
		public ufbx_string name;
		public ufbx_dom_node_list children;
		public ufbx_dom_value_list values;
	}

	// -- Properties

	public enum ufbx_prop_type : int32
	{
		UFBX_PROP_UNKNOWN,
		UFBX_PROP_BOOLEAN,
		UFBX_PROP_INTEGER,
		UFBX_PROP_NUMBER,
		UFBX_PROP_VECTOR,
		UFBX_PROP_COLOR,
		UFBX_PROP_COLOR_WITH_ALPHA,
		UFBX_PROP_STRING,
		UFBX_PROP_DATE_TIME,
		UFBX_PROP_TRANSLATION,
		UFBX_PROP_ROTATION,
		UFBX_PROP_SCALING,
		UFBX_PROP_DISTANCE,
		UFBX_PROP_COMPOUND,
		UFBX_PROP_BLOB,
		UFBX_PROP_REFERENCE,
	}

	public enum ufbx_prop_flags : uint32
	{
		UFBX_PROP_FLAG_ANIMATABLE = 0x1,
		UFBX_PROP_FLAG_USER_DEFINED = 0x2,
		UFBX_PROP_FLAG_HIDDEN = 0x4,
		UFBX_PROP_FLAG_LOCK_X = 0x10,
		UFBX_PROP_FLAG_LOCK_Y = 0x20,
		UFBX_PROP_FLAG_LOCK_Z = 0x40,
		UFBX_PROP_FLAG_LOCK_W = 0x80,
		UFBX_PROP_FLAG_MUTE_X = 0x100,
		UFBX_PROP_FLAG_MUTE_Y = 0x200,
		UFBX_PROP_FLAG_MUTE_Z = 0x400,
		UFBX_PROP_FLAG_MUTE_W = 0x800,
		UFBX_PROP_FLAG_SYNTHETIC = 0x1000,
		UFBX_PROP_FLAG_ANIMATED = 0x2000,
		UFBX_PROP_FLAG_NOT_FOUND = 0x4000,
		UFBX_PROP_FLAG_CONNECTED = 0x8000,
		UFBX_PROP_FLAG_NO_VALUE = 0x10000,
		UFBX_PROP_FLAG_OVERRIDDEN = 0x20000,
		UFBX_PROP_FLAG_VALUE_REAL = 0x100000,
		UFBX_PROP_FLAG_VALUE_VEC2 = 0x200000,
		UFBX_PROP_FLAG_VALUE_VEC3 = 0x400000,
		UFBX_PROP_FLAG_VALUE_VEC4 = 0x800000,
		UFBX_PROP_FLAG_VALUE_INT  = 0x01000000,
		UFBX_PROP_FLAG_VALUE_STR  = 0x02000000,
		UFBX_PROP_FLAG_VALUE_BLOB = 0x04000000,
	}

	[CRepr]
	public struct ufbx_prop
	{
		public ufbx_string name;

		public uint32 _internal_key;

		public ufbx_prop_type type;
		public ufbx_prop_flags flags;

		public ufbx_string value_str;
		public ufbx_blob value_blob;
		public int64 value_int;

		[Union] public using struct
		{
			public ufbx_real[4] value_real_arr;
			public ufbx_real value_real;
			public ufbx_vec2 value_vec2;
			public ufbx_vec3 value_vec3;
			public ufbx_vec4 value_vec4;
		};
	}

	[CRepr]
	public struct ufbx_prop_list
	{
		public ufbx_prop* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_props
	{
		public ufbx_prop_list props;
		public uint num_animated;
		public ufbx_props* defaults;
	}

	// -- Elements

	// Element pointer list types

	[CRepr]
	public struct ufbx_element_list
	{
		public ufbx_element** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_unknown_list
	{
		public ufbx_unknown** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_node_list
	{
		public ufbx_node** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_mesh_list
	{
		public ufbx_mesh** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_light_list
	{
		public ufbx_light** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_camera_list
	{
		public ufbx_camera** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_bone_list
	{
		public ufbx_bone** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_empty_list
	{
		public ufbx_empty** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_line_curve_list
	{
		public ufbx_line_curve** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_nurbs_curve_list
	{
		public ufbx_nurbs_curve** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_nurbs_surface_list
	{
		public ufbx_nurbs_surface** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_nurbs_trim_surface_list
	{
		public ufbx_nurbs_trim_surface** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_nurbs_trim_boundary_list
	{
		public ufbx_nurbs_trim_boundary** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_procedural_geometry_list
	{
		public ufbx_procedural_geometry** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_stereo_camera_list
	{
		public ufbx_stereo_camera** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_camera_switcher_list
	{
		public ufbx_camera_switcher** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_marker_list
	{
		public ufbx_marker** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_lod_group_list
	{
		public ufbx_lod_group** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_skin_deformer_list
	{
		public ufbx_skin_deformer** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_skin_cluster_list
	{
		public ufbx_skin_cluster** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_blend_deformer_list
	{
		public ufbx_blend_deformer** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_blend_channel_list
	{
		public ufbx_blend_channel** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_blend_shape_list
	{
		public ufbx_blend_shape** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_cache_deformer_list
	{
		public ufbx_cache_deformer** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_cache_file_list
	{
		public ufbx_cache_file** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_material_list
	{
		public ufbx_material** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_texture_list
	{
		public ufbx_texture** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_video_list
	{
		public ufbx_video** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_shader_list
	{
		public ufbx_shader** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_shader_binding_list
	{
		public ufbx_shader_binding** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_anim_stack_list
	{
		public ufbx_anim_stack** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_anim_layer_list
	{
		public ufbx_anim_layer** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_anim_value_list
	{
		public ufbx_anim_value** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_anim_curve_list
	{
		public ufbx_anim_curve** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_display_layer_list
	{
		public ufbx_display_layer** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_selection_set_list
	{
		public ufbx_selection_set** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_selection_node_list
	{
		public ufbx_selection_node** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_character_list
	{
		public ufbx_character** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_constraint_list
	{
		public ufbx_constraint** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_audio_layer_list
	{
		public ufbx_audio_layer** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_audio_clip_list
	{
		public ufbx_audio_clip** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_pose_list
	{
		public ufbx_pose** data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_metadata_object_list
	{
		public ufbx_metadata_object** data;
		public uint count;
	}

	[AllowDuplicates]
	public enum ufbx_element_type : int32
	{
		UFBX_ELEMENT_UNKNOWN,
		UFBX_ELEMENT_NODE,
		UFBX_ELEMENT_MESH,
		UFBX_ELEMENT_LIGHT,
		UFBX_ELEMENT_CAMERA,
		UFBX_ELEMENT_BONE,
		UFBX_ELEMENT_EMPTY,
		UFBX_ELEMENT_LINE_CURVE,
		UFBX_ELEMENT_NURBS_CURVE,
		UFBX_ELEMENT_NURBS_SURFACE,
		UFBX_ELEMENT_NURBS_TRIM_SURFACE,
		UFBX_ELEMENT_NURBS_TRIM_BOUNDARY,
		UFBX_ELEMENT_PROCEDURAL_GEOMETRY,
		UFBX_ELEMENT_STEREO_CAMERA,
		UFBX_ELEMENT_CAMERA_SWITCHER,
		UFBX_ELEMENT_MARKER,
		UFBX_ELEMENT_LOD_GROUP,
		UFBX_ELEMENT_SKIN_DEFORMER,
		UFBX_ELEMENT_SKIN_CLUSTER,
		UFBX_ELEMENT_BLEND_DEFORMER,
		UFBX_ELEMENT_BLEND_CHANNEL,
		UFBX_ELEMENT_BLEND_SHAPE,
		UFBX_ELEMENT_CACHE_DEFORMER,
		UFBX_ELEMENT_CACHE_FILE,
		UFBX_ELEMENT_MATERIAL,
		UFBX_ELEMENT_TEXTURE,
		UFBX_ELEMENT_VIDEO,
		UFBX_ELEMENT_SHADER,
		UFBX_ELEMENT_SHADER_BINDING,
		UFBX_ELEMENT_ANIM_STACK,
		UFBX_ELEMENT_ANIM_LAYER,
		UFBX_ELEMENT_ANIM_VALUE,
		UFBX_ELEMENT_ANIM_CURVE,
		UFBX_ELEMENT_DISPLAY_LAYER,
		UFBX_ELEMENT_SELECTION_SET,
		UFBX_ELEMENT_SELECTION_NODE,
		UFBX_ELEMENT_CHARACTER,
		UFBX_ELEMENT_CONSTRAINT,
		UFBX_ELEMENT_AUDIO_LAYER,
		UFBX_ELEMENT_AUDIO_CLIP,
		UFBX_ELEMENT_POSE,
		UFBX_ELEMENT_METADATA_OBJECT,

		UFBX_ELEMENT_TYPE_FIRST_ATTRIB = UFBX_ELEMENT_MESH,
		UFBX_ELEMENT_TYPE_LAST_ATTRIB = UFBX_ELEMENT_LOD_GROUP,
	}

	[CRepr]
	public struct ufbx_connection
	{
		public ufbx_element* src;
		public ufbx_element* dst;
		public ufbx_string src_prop;
		public ufbx_string dst_prop;
	}

	[CRepr]
	public struct ufbx_connection_list
	{
		public ufbx_connection* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_element
	{
		public ufbx_string name;
		public ufbx_props props;
		public uint32 element_id;
		public uint32 typed_id;
		public ufbx_node_list instances;
		public ufbx_element_type type;
		public ufbx_connection_list connections_src;
		public ufbx_connection_list connections_dst;
		public ufbx_dom_node* dom_node;
		public ufbx_scene* scene;
	}


	public enum ufbx_inherit_mode : int32
	{
		UFBX_INHERIT_MODE_NORMAL,
		UFBX_INHERIT_MODE_IGNORE_PARENT_SCALE,
		UFBX_INHERIT_MODE_COMPONENTWISE_SCALE,
	}

	public enum ufbx_mirror_axis : int32
	{
		UFBX_MIRROR_AXIS_NONE,
		UFBX_MIRROR_AXIS_X,
		UFBX_MIRROR_AXIS_Y,
		UFBX_MIRROR_AXIS_Z,
	}

	public enum ufbx_light_type : int32
	{
		UFBX_LIGHT_POINT,
		UFBX_LIGHT_DIRECTIONAL,
		UFBX_LIGHT_SPOT,
		UFBX_LIGHT_AREA,
		UFBX_LIGHT_VOLUME,
	}

	public enum ufbx_light_decay : int32
	{
		UFBX_LIGHT_DECAY_NONE,
		UFBX_LIGHT_DECAY_LINEAR,
		UFBX_LIGHT_DECAY_QUADRATIC,
		UFBX_LIGHT_DECAY_CUBIC,
	}

	public enum ufbx_light_area_shape : int32
	{
		UFBX_LIGHT_AREA_SHAPE_RECTANGLE,
		UFBX_LIGHT_AREA_SHAPE_SPHERE,
	}

	public enum ufbx_projection_mode : int32
	{
		UFBX_PROJECTION_MODE_PERSPECTIVE,
		UFBX_PROJECTION_MODE_ORTHOGRAPHIC,
	}

	public enum ufbx_aspect_mode : int32
	{
		UFBX_ASPECT_MODE_WINDOW_SIZE,
		UFBX_ASPECT_MODE_FIXED_RATIO,
		UFBX_ASPECT_MODE_FIXED_RESOLUTION,
		UFBX_ASPECT_MODE_FIXED_WIDTH,
		UFBX_ASPECT_MODE_FIXED_HEIGHT,
	}

	public enum ufbx_aperture_mode : int32
	{
		UFBX_APERTURE_MODE_HORIZONTAL_AND_VERTICAL,
		UFBX_APERTURE_MODE_HORIZONTAL,
		UFBX_APERTURE_MODE_VERTICAL,
		UFBX_APERTURE_MODE_FOCAL_LENGTH,
	}

	public enum ufbx_gate_fit : int32
	{
		UFBX_GATE_FIT_NONE,
		UFBX_GATE_FIT_VERTICAL,
		UFBX_GATE_FIT_HORIZONTAL,
		UFBX_GATE_FIT_FILL,
		UFBX_GATE_FIT_OVERSCAN,
		UFBX_GATE_FIT_STRETCH,
	}

	public enum ufbx_aperture_format : int32
	{
		UFBX_APERTURE_FORMAT_CUSTOM,
		UFBX_APERTURE_FORMAT_16MM_THEATRICAL,
		UFBX_APERTURE_FORMAT_SUPER_16MM,
		UFBX_APERTURE_FORMAT_35MM_ACADEMY,
		UFBX_APERTURE_FORMAT_35MM_TV_PROJECTION,
		UFBX_APERTURE_FORMAT_35MM_FULL_APERTURE,
		UFBX_APERTURE_FORMAT_35MM_185_PROJECTION,
		UFBX_APERTURE_FORMAT_35MM_ANAMORPHIC,
		UFBX_APERTURE_FORMAT_70MM_PROJECTION,
		UFBX_APERTURE_FORMAT_VISTAVISION,
		UFBX_APERTURE_FORMAT_DYNAVISION,
		UFBX_APERTURE_FORMAT_IMAX,
	}

	public enum ufbx_coordinate_axis : int32
	{
		UFBX_COORDINATE_AXIS_POSITIVE_X,
		UFBX_COORDINATE_AXIS_NEGATIVE_X,
		UFBX_COORDINATE_AXIS_POSITIVE_Y,
		UFBX_COORDINATE_AXIS_NEGATIVE_Y,
		UFBX_COORDINATE_AXIS_POSITIVE_Z,
		UFBX_COORDINATE_AXIS_NEGATIVE_Z,
		UFBX_COORDINATE_AXIS_UNKNOWN,
	}

	public enum ufbx_nurbs_topology : int32
	{
		UFBX_NURBS_TOPOLOGY_OPEN,
		UFBX_NURBS_TOPOLOGY_PERIODIC,
		UFBX_NURBS_TOPOLOGY_CLOSED,
	}

	public enum ufbx_marker_type : int32
	{
		UFBX_MARKER_UNKNOWN,
		UFBX_MARKER_FK_EFFECTOR,
		UFBX_MARKER_IK_EFFECTOR,
	}

	public enum ufbx_lod_display : int32
	{
		UFBX_LOD_DISPLAY_USE_LOD,
		UFBX_LOD_DISPLAY_SHOW,
		UFBX_LOD_DISPLAY_HIDE,
	}

	public enum ufbx_subdivision_display_mode : int32
	{
		UFBX_SUBDIVISION_DISPLAY_DISABLED,
		UFBX_SUBDIVISION_DISPLAY_HULL,
		UFBX_SUBDIVISION_DISPLAY_HULL_AND_SMOOTH,
		UFBX_SUBDIVISION_DISPLAY_SMOOTH,
	}

	public enum ufbx_subdivision_boundary : int32
	{
		UFBX_SUBDIVISION_BOUNDARY_DEFAULT,
		UFBX_SUBDIVISION_BOUNDARY_LEGACY,
		UFBX_SUBDIVISION_BOUNDARY_SHARP_CORNERS,
		UFBX_SUBDIVISION_BOUNDARY_SHARP_NONE,
		UFBX_SUBDIVISION_BOUNDARY_SHARP_BOUNDARY,
		UFBX_SUBDIVISION_BOUNDARY_SHARP_INTERIOR,
	}

	public enum ufbx_skinning_method : int32
	{
		UFBX_SKINNING_METHOD_LINEAR,
		UFBX_SKINNING_METHOD_RIGID,
		UFBX_SKINNING_METHOD_DUAL_QUATERNION,
		UFBX_SKINNING_METHOD_BLENDED_DQ_LINEAR,
	}

	public enum ufbx_cache_file_format : int32
	{
		UFBX_CACHE_FILE_FORMAT_UNKNOWN,
		UFBX_CACHE_FILE_FORMAT_PC2,
		UFBX_CACHE_FILE_FORMAT_MC,
	}

	public enum ufbx_cache_data_format : int32
	{
		UFBX_CACHE_DATA_FORMAT_UNKNOWN,
		UFBX_CACHE_DATA_FORMAT_REAL_FLOAT,
		UFBX_CACHE_DATA_FORMAT_VEC3_FLOAT,
		UFBX_CACHE_DATA_FORMAT_REAL_DOUBLE,
		UFBX_CACHE_DATA_FORMAT_VEC3_DOUBLE,
	}

	public enum ufbx_cache_data_encoding : int32
	{
		UFBX_CACHE_DATA_ENCODING_UNKNOWN,
		UFBX_CACHE_DATA_ENCODING_LITTLE_ENDIAN,
		UFBX_CACHE_DATA_ENCODING_BIG_ENDIAN,
	}

	public enum ufbx_cache_interpretation : int32
	{
		UFBX_CACHE_INTERPRETATION_UNKNOWN,
		UFBX_CACHE_INTERPRETATION_POINTS,
		UFBX_CACHE_INTERPRETATION_VERTEX_POSITION,
		UFBX_CACHE_INTERPRETATION_VERTEX_NORMAL,
	}

	public enum ufbx_shader_type : int32
	{
		UFBX_SHADER_UNKNOWN,
		UFBX_SHADER_FBX_LAMBERT,
		UFBX_SHADER_FBX_PHONG,
		UFBX_SHADER_OSL_STANDARD_SURFACE,
		UFBX_SHADER_ARNOLD_STANDARD_SURFACE,
		UFBX_SHADER_3DS_MAX_PHYSICAL_MATERIAL,
		UFBX_SHADER_3DS_MAX_PBR_METAL_ROUGH,
		UFBX_SHADER_3DS_MAX_PBR_SPEC_GLOSS,
		UFBX_SHADER_GLTF_MATERIAL,
		UFBX_SHADER_OPENPBR_MATERIAL,
		UFBX_SHADER_SHADERFX_GRAPH,
		UFBX_SHADER_BLENDER_PHONG,
		UFBX_SHADER_WAVEFRONT_MTL,
	}

	public enum ufbx_material_fbx_map : int32
	{
		UFBX_MATERIAL_FBX_DIFFUSE_FACTOR,
		UFBX_MATERIAL_FBX_DIFFUSE_COLOR,
		UFBX_MATERIAL_FBX_SPECULAR_FACTOR,
		UFBX_MATERIAL_FBX_SPECULAR_COLOR,
		UFBX_MATERIAL_FBX_SPECULAR_EXPONENT,
		UFBX_MATERIAL_FBX_REFLECTION_FACTOR,
		UFBX_MATERIAL_FBX_REFLECTION_COLOR,
		UFBX_MATERIAL_FBX_TRANSPARENCY_FACTOR,
		UFBX_MATERIAL_FBX_TRANSPARENCY_COLOR,
		UFBX_MATERIAL_FBX_EMISSION_FACTOR,
		UFBX_MATERIAL_FBX_EMISSION_COLOR,
		UFBX_MATERIAL_FBX_AMBIENT_FACTOR,
		UFBX_MATERIAL_FBX_AMBIENT_COLOR,
		UFBX_MATERIAL_FBX_NORMAL_MAP,
		UFBX_MATERIAL_FBX_BUMP,
		UFBX_MATERIAL_FBX_BUMP_FACTOR,
		UFBX_MATERIAL_FBX_DISPLACEMENT_FACTOR,
		UFBX_MATERIAL_FBX_DISPLACEMENT,
		UFBX_MATERIAL_FBX_VECTOR_DISPLACEMENT_FACTOR,
		UFBX_MATERIAL_FBX_VECTOR_DISPLACEMENT,
	}

	public enum ufbx_material_pbr_map : int32
	{
		UFBX_MATERIAL_PBR_BASE_FACTOR,
		UFBX_MATERIAL_PBR_BASE_COLOR,
		UFBX_MATERIAL_PBR_ROUGHNESS,
		UFBX_MATERIAL_PBR_METALNESS,
		UFBX_MATERIAL_PBR_DIFFUSE_ROUGHNESS,
		UFBX_MATERIAL_PBR_SPECULAR_FACTOR,
		UFBX_MATERIAL_PBR_SPECULAR_COLOR,
		UFBX_MATERIAL_PBR_SPECULAR_IOR,
		UFBX_MATERIAL_PBR_SPECULAR_ANISOTROPY,
		UFBX_MATERIAL_PBR_SPECULAR_ROTATION,
		UFBX_MATERIAL_PBR_TRANSMISSION_FACTOR,
		UFBX_MATERIAL_PBR_TRANSMISSION_COLOR,
		UFBX_MATERIAL_PBR_TRANSMISSION_DEPTH,
		UFBX_MATERIAL_PBR_TRANSMISSION_SCATTER,
		UFBX_MATERIAL_PBR_TRANSMISSION_SCATTER_ANISOTROPY,
		UFBX_MATERIAL_PBR_TRANSMISSION_DISPERSION,
		UFBX_MATERIAL_PBR_TRANSMISSION_ROUGHNESS,
		UFBX_MATERIAL_PBR_TRANSMISSION_EXTRA_ROUGHNESS,
		UFBX_MATERIAL_PBR_TRANSMISSION_PRIORITY,
		UFBX_MATERIAL_PBR_TRANSMISSION_ENABLE_IN_AOV,
		UFBX_MATERIAL_PBR_SUBSURFACE_FACTOR,
		UFBX_MATERIAL_PBR_SUBSURFACE_COLOR,
		UFBX_MATERIAL_PBR_SUBSURFACE_RADIUS,
		UFBX_MATERIAL_PBR_SUBSURFACE_SCALE,
		UFBX_MATERIAL_PBR_SUBSURFACE_ANISOTROPY,
		UFBX_MATERIAL_PBR_SUBSURFACE_TINT_COLOR,
		UFBX_MATERIAL_PBR_SUBSURFACE_TYPE,
		UFBX_MATERIAL_PBR_SHEEN_FACTOR,
		UFBX_MATERIAL_PBR_SHEEN_COLOR,
		UFBX_MATERIAL_PBR_SHEEN_ROUGHNESS,
		UFBX_MATERIAL_PBR_COAT_FACTOR,
		UFBX_MATERIAL_PBR_COAT_COLOR,
		UFBX_MATERIAL_PBR_COAT_ROUGHNESS,
		UFBX_MATERIAL_PBR_COAT_IOR,
		UFBX_MATERIAL_PBR_COAT_ANISOTROPY,
		UFBX_MATERIAL_PBR_COAT_ROTATION,
		UFBX_MATERIAL_PBR_COAT_NORMAL,
		UFBX_MATERIAL_PBR_COAT_AFFECT_BASE_COLOR,
		UFBX_MATERIAL_PBR_COAT_AFFECT_BASE_ROUGHNESS,
		UFBX_MATERIAL_PBR_THIN_FILM_FACTOR,
		UFBX_MATERIAL_PBR_THIN_FILM_THICKNESS,
		UFBX_MATERIAL_PBR_THIN_FILM_IOR,
		UFBX_MATERIAL_PBR_EMISSION_FACTOR,
		UFBX_MATERIAL_PBR_EMISSION_COLOR,
		UFBX_MATERIAL_PBR_OPACITY,
		UFBX_MATERIAL_PBR_INDIRECT_DIFFUSE,
		UFBX_MATERIAL_PBR_INDIRECT_SPECULAR,
		UFBX_MATERIAL_PBR_NORMAL_MAP,
		UFBX_MATERIAL_PBR_TANGENT_MAP,
		UFBX_MATERIAL_PBR_DISPLACEMENT_MAP,
		UFBX_MATERIAL_PBR_MATTE_FACTOR,
		UFBX_MATERIAL_PBR_MATTE_COLOR,
		UFBX_MATERIAL_PBR_AMBIENT_OCCLUSION,
		UFBX_MATERIAL_PBR_GLOSSINESS,
		UFBX_MATERIAL_PBR_COAT_GLOSSINESS,
		UFBX_MATERIAL_PBR_TRANSMISSION_GLOSSINESS,
	}

	public enum ufbx_material_feature : int32
	{
		UFBX_MATERIAL_FEATURE_PBR,
		UFBX_MATERIAL_FEATURE_METALNESS,
		UFBX_MATERIAL_FEATURE_DIFFUSE,
		UFBX_MATERIAL_FEATURE_SPECULAR,
		UFBX_MATERIAL_FEATURE_EMISSION,
		UFBX_MATERIAL_FEATURE_TRANSMISSION,
		UFBX_MATERIAL_FEATURE_COAT,
		UFBX_MATERIAL_FEATURE_SHEEN,
		UFBX_MATERIAL_FEATURE_OPACITY,
		UFBX_MATERIAL_FEATURE_AMBIENT_OCCLUSION,
		UFBX_MATERIAL_FEATURE_MATTE,
		UFBX_MATERIAL_FEATURE_UNLIT,
		UFBX_MATERIAL_FEATURE_IOR,
		UFBX_MATERIAL_FEATURE_DIFFUSE_ROUGHNESS,
		UFBX_MATERIAL_FEATURE_TRANSMISSION_ROUGHNESS,
		UFBX_MATERIAL_FEATURE_THIN_WALLED,
		UFBX_MATERIAL_FEATURE_CAUSTICS,
		UFBX_MATERIAL_FEATURE_EXIT_TO_BACKGROUND,
		UFBX_MATERIAL_FEATURE_INTERNAL_REFLECTIONS,
		UFBX_MATERIAL_FEATURE_DOUBLE_SIDED,
		UFBX_MATERIAL_FEATURE_ROUGHNESS_AS_GLOSSINESS,
		UFBX_MATERIAL_FEATURE_COAT_ROUGHNESS_AS_GLOSSINESS,
		UFBX_MATERIAL_FEATURE_TRANSMISSION_ROUGHNESS_AS_GLOSSINESS,
	}

	public enum ufbx_texture_type : int32
	{
		UFBX_TEXTURE_FILE,
		UFBX_TEXTURE_LAYERED,
		UFBX_TEXTURE_PROCEDURAL,
		UFBX_TEXTURE_SHADER,
	}

	public enum ufbx_blend_mode : int32
	{
		UFBX_BLEND_TRANSLUCENT,
		UFBX_BLEND_ADDITIVE,
		UFBX_BLEND_MULTIPLY,
		UFBX_BLEND_MULTIPLY_2X,
		UFBX_BLEND_OVER,
		UFBX_BLEND_REPLACE,
		UFBX_BLEND_DISSOLVE,
		UFBX_BLEND_DARKEN,
		UFBX_BLEND_COLOR_BURN,
		UFBX_BLEND_LINEAR_BURN,
		UFBX_BLEND_DARKER_COLOR,
		UFBX_BLEND_LIGHTEN,
		UFBX_BLEND_SCREEN,
		UFBX_BLEND_COLOR_DODGE,
		UFBX_BLEND_LINEAR_DODGE,
		UFBX_BLEND_LIGHTER_COLOR,
		UFBX_BLEND_SOFT_LIGHT,
		UFBX_BLEND_HARD_LIGHT,
		UFBX_BLEND_VIVID_LIGHT,
		UFBX_BLEND_LINEAR_LIGHT,
		UFBX_BLEND_PIN_LIGHT,
		UFBX_BLEND_HARD_MIX,
		UFBX_BLEND_DIFFERENCE,
		UFBX_BLEND_EXCLUSION,
		UFBX_BLEND_SUBTRACT,
		UFBX_BLEND_DIVIDE,
		UFBX_BLEND_HUE,
		UFBX_BLEND_SATURATION,
		UFBX_BLEND_COLOR,
		UFBX_BLEND_LUMINOSITY,
		UFBX_BLEND_OVERLAY,
	}

	public enum ufbx_wrap_mode : int32
	{
		UFBX_WRAP_REPEAT,
		UFBX_WRAP_CLAMP,
	}

	public enum ufbx_shader_texture_type : int32
	{
		UFBX_SHADER_TEXTURE_UNKNOWN,
		UFBX_SHADER_TEXTURE_SELECT_OUTPUT,
		UFBX_SHADER_TEXTURE_OSL,
	}

	public enum ufbx_interpolation : int32
	{
		UFBX_INTERPOLATION_CONSTANT_PREV,
		UFBX_INTERPOLATION_CONSTANT_NEXT,
		UFBX_INTERPOLATION_LINEAR,
		UFBX_INTERPOLATION_CUBIC,
	}

	public enum ufbx_extrapolation_mode : int32
	{
		UFBX_EXTRAPOLATION_CONSTANT,
		UFBX_EXTRAPOLATION_REPEAT,
		UFBX_EXTRAPOLATION_MIRROR,
		UFBX_EXTRAPOLATION_SLOPE,
		UFBX_EXTRAPOLATION_REPEAT_RELATIVE,
	}

	public enum ufbx_constraint_type : int32
	{
		UFBX_CONSTRAINT_UNKNOWN,
		UFBX_CONSTRAINT_AIM,
		UFBX_CONSTRAINT_PARENT,
		UFBX_CONSTRAINT_POSITION,
		UFBX_CONSTRAINT_ROTATION,
		UFBX_CONSTRAINT_SCALE,
		UFBX_CONSTRAINT_SINGLE_CHAIN_IK,
	}

	public enum ufbx_constraint_aim_up_type : int32
	{
		UFBX_CONSTRAINT_AIM_UP_SCENE,
		UFBX_CONSTRAINT_AIM_UP_TO_NODE,
		UFBX_CONSTRAINT_AIM_UP_ALIGN_NODE,
		UFBX_CONSTRAINT_AIM_UP_VECTOR,
		UFBX_CONSTRAINT_AIM_UP_NONE,
	}

	public enum ufbx_constraint_ik_pole_type : int32
	{
		UFBX_CONSTRAINT_IK_POLE_VECTOR,
		UFBX_CONSTRAINT_IK_POLE_NODE,
	}

	// -- Helper structs --

	[CRepr]
	public struct ufbx_vertex_attrib
	{
		public bool exists;
		public ufbx_void_list values;
		public ufbx_uint32_list indices;
		public uint value_reals;
		public bool unique_per_vertex;
		public ufbx_real_list values_w;
	}

	[CRepr]
	public struct ufbx_vertex_real
	{
		public bool exists;
		public ufbx_real_list values;
		public ufbx_uint32_list indices;
		public uint value_reals;
		public bool unique_per_vertex;
		public ufbx_real_list values_w;
	}

	[CRepr]
	public struct ufbx_vertex_vec2
	{
		public bool exists;
		public ufbx_vec2_list values;
		public ufbx_uint32_list indices;
		public uint value_reals;
		public bool unique_per_vertex;
		public ufbx_real_list values_w;
	}

	[CRepr]
	public struct ufbx_vertex_vec3
	{
		public bool exists;
		public ufbx_vec3_list values;
		public ufbx_uint32_list indices;
		public uint value_reals;
		public bool unique_per_vertex;
		public ufbx_real_list values_w;
	}

	[CRepr]
	public struct ufbx_vertex_vec4
	{
		public bool exists;
		public ufbx_vec4_list values;
		public ufbx_uint32_list indices;
		public uint value_reals;
		public bool unique_per_vertex;
		public ufbx_real_list values_w;
	}

	[CRepr]
	public struct ufbx_uv_set
	{
		public ufbx_string name;
		public uint32 index;
		public ufbx_vertex_vec2 vertex_uv;
		public ufbx_vertex_vec3 vertex_tangent;
		public ufbx_vertex_vec3 vertex_bitangent;
	}

	[CRepr]
	public struct ufbx_color_set
	{
		public ufbx_string name;
		public uint32 index;
		public ufbx_vertex_vec4 vertex_color;
	}

	[CRepr]
	public struct ufbx_uv_set_list
	{
		public ufbx_uv_set* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_color_set_list
	{
		public ufbx_color_set* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_edge
	{
		[Union]
		public using struct
		{
			public uint32[2] indices;
		};
		// Access a/b via indices[0] and indices[1]
	}

	[CRepr]
	public struct ufbx_edge_list
	{
		public ufbx_edge* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_face
	{
		public uint32 index_begin;
		public uint32 num_indices;
	}

	[CRepr]
	public struct ufbx_face_list
	{
		public ufbx_face* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_mesh_part
	{
		public uint32 index;
		public uint num_faces;
		public uint num_triangles;
		public uint num_empty_faces;
		public uint num_point_faces;
		public uint num_line_faces;
		public ufbx_uint32_list face_indices;
	}

	[CRepr]
	public struct ufbx_mesh_part_list
	{
		public ufbx_mesh_part* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_face_group
	{
		public int32 id;
		public ufbx_string name;
	}

	[CRepr]
	public struct ufbx_face_group_list
	{
		public ufbx_face_group* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_subdivision_weight_range
	{
		public uint32 weight_begin;
		public uint32 num_weights;
	}

	[CRepr]
	public struct ufbx_subdivision_weight_range_list
	{
		public ufbx_subdivision_weight_range* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_subdivision_weight
	{
		public ufbx_real weight;
		public uint32 index;
	}

	[CRepr]
	public struct ufbx_subdivision_weight_list
	{
		public ufbx_subdivision_weight* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_subdivision_result
	{
		public uint result_memory_used;
		public uint temp_memory_used;
		public uint result_allocs;
		public uint temp_allocs;
		public ufbx_subdivision_weight_range_list source_vertex_ranges;
		public ufbx_subdivision_weight_list source_vertex_weights;
		public ufbx_subdivision_weight_range_list skin_cluster_ranges;
		public ufbx_subdivision_weight_list skin_cluster_weights;
	}

	[CRepr]
	public struct ufbx_coordinate_axes
	{
		public ufbx_coordinate_axis right;
		public ufbx_coordinate_axis up;
		public ufbx_coordinate_axis front;
	}

	[CRepr]
	public struct ufbx_line_segment
	{
		public uint32 index_begin;
		public uint32 num_indices;
	}

	[CRepr]
	public struct ufbx_line_segment_list
	{
		public ufbx_line_segment* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_nurbs_basis
	{
		public uint32 order;
		public ufbx_nurbs_topology topology;
		public ufbx_real_list knot_vector;
		public ufbx_real t_min;
		public ufbx_real t_max;
		public ufbx_real_list spans;
		public bool is_2d;
		public uint num_wrap_control_points;
		public bool valid;
	}

	[CRepr]
	public struct ufbx_lod_level
	{
		public ufbx_real distance;
		public ufbx_lod_display display;
	}

	[CRepr]
	public struct ufbx_lod_level_list
	{
		public ufbx_lod_level* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_skin_vertex
	{
		public uint32 weight_begin;
		public uint32 num_weights;
		public ufbx_real dq_weight;
	}

	[CRepr]
	public struct ufbx_skin_vertex_list
	{
		public ufbx_skin_vertex* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_skin_weight
	{
		public uint32 cluster_index;
		public ufbx_real weight;
	}

	[CRepr]
	public struct ufbx_skin_weight_list
	{
		public ufbx_skin_weight* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_blend_keyframe
	{
		public ufbx_blend_shape* shape;
		public ufbx_real target_weight;
		public ufbx_real effective_weight;
	}

	[CRepr]
	public struct ufbx_blend_keyframe_list
	{
		public ufbx_blend_keyframe* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_cache_frame
	{
		public ufbx_string channel;
		public double time;
		public ufbx_string filename;
		public ufbx_cache_file_format file_format;
		public ufbx_mirror_axis mirror_axis;
		public ufbx_real scale_factor;
		public ufbx_cache_data_format data_format;
		public ufbx_cache_data_encoding data_encoding;
		public uint64 data_offset;
		public uint32 data_count;
		public uint32 data_element_bytes;
		public uint64 data_total_bytes;
	}

	[CRepr]
	public struct ufbx_cache_frame_list
	{
		public ufbx_cache_frame* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_cache_channel
	{
		public ufbx_string name;
		public ufbx_cache_interpretation interpretation;
		public ufbx_string interpretation_name;
		public ufbx_cache_frame_list frames;
		public ufbx_mirror_axis mirror_axis;
		public ufbx_real scale_factor;
	}

	[CRepr]
	public struct ufbx_cache_channel_list
	{
		public ufbx_cache_channel* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_geometry_cache
	{
		public ufbx_string root_filename;
		public ufbx_cache_channel_list channels;
		public ufbx_cache_frame_list frames;
		public ufbx_string_list extra_info;
	}

	[CRepr]
	public struct ufbx_material_map
	{
		[Union]
		public using struct
		{
			public ufbx_real value_real;
			public ufbx_vec2 value_vec2;
			public ufbx_vec3 value_vec3;
			public ufbx_vec4 value_vec4;
		};
		public int64 value_int;
		public ufbx_texture* texture;
		public bool has_value;
		public bool texture_enabled;
		public bool feature_disabled;
		public uint8 value_components;
	}

	[CRepr]
	public struct ufbx_material_feature_info
	{
		public bool enabled;
		public bool is_explicit;
	}

	[CRepr]
	public struct ufbx_material_texture
	{
		public ufbx_string material_prop;
		public ufbx_string shader_prop;
		public ufbx_texture* texture;
	}

	[CRepr]
	public struct ufbx_material_texture_list
	{
		public ufbx_material_texture* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_material_fbx_maps
	{
		public ufbx_material_map diffuse_factor;
		public ufbx_material_map diffuse_color;
		public ufbx_material_map specular_factor;
		public ufbx_material_map specular_color;
		public ufbx_material_map specular_exponent;
		public ufbx_material_map reflection_factor;
		public ufbx_material_map reflection_color;
		public ufbx_material_map transparency_factor;
		public ufbx_material_map transparency_color;
		public ufbx_material_map emission_factor;
		public ufbx_material_map emission_color;
		public ufbx_material_map ambient_factor;
		public ufbx_material_map ambient_color;
		public ufbx_material_map normal_map;
		public ufbx_material_map bump;
		public ufbx_material_map bump_factor;
		public ufbx_material_map displacement_factor;
		public ufbx_material_map displacement;
		public ufbx_material_map vector_displacement_factor;
		public ufbx_material_map vector_displacement;
	}

	[CRepr]
	public struct ufbx_material_pbr_maps
	{
		public ufbx_material_map base_factor;
		public ufbx_material_map base_color;
		public ufbx_material_map roughness;
		public ufbx_material_map metalness;
		public ufbx_material_map diffuse_roughness;
		public ufbx_material_map specular_factor;
		public ufbx_material_map specular_color;
		public ufbx_material_map specular_ior;
		public ufbx_material_map specular_anisotropy;
		public ufbx_material_map specular_rotation;
		public ufbx_material_map transmission_factor;
		public ufbx_material_map transmission_color;
		public ufbx_material_map transmission_depth;
		public ufbx_material_map transmission_scatter;
		public ufbx_material_map transmission_scatter_anisotropy;
		public ufbx_material_map transmission_dispersion;
		public ufbx_material_map transmission_roughness;
		public ufbx_material_map transmission_extra_roughness;
		public ufbx_material_map transmission_priority;
		public ufbx_material_map transmission_enable_in_aov;
		public ufbx_material_map subsurface_factor;
		public ufbx_material_map subsurface_color;
		public ufbx_material_map subsurface_radius;
		public ufbx_material_map subsurface_scale;
		public ufbx_material_map subsurface_anisotropy;
		public ufbx_material_map subsurface_tint_color;
		public ufbx_material_map subsurface_type;
		public ufbx_material_map sheen_factor;
		public ufbx_material_map sheen_color;
		public ufbx_material_map sheen_roughness;
		public ufbx_material_map coat_factor;
		public ufbx_material_map coat_color;
		public ufbx_material_map coat_roughness;
		public ufbx_material_map coat_ior;
		public ufbx_material_map coat_anisotropy;
		public ufbx_material_map coat_rotation;
		public ufbx_material_map coat_normal;
		public ufbx_material_map coat_affect_base_color;
		public ufbx_material_map coat_affect_base_roughness;
		public ufbx_material_map thin_film_factor;
		public ufbx_material_map thin_film_thickness;
		public ufbx_material_map thin_film_ior;
		public ufbx_material_map emission_factor;
		public ufbx_material_map emission_color;
		public ufbx_material_map opacity;
		public ufbx_material_map indirect_diffuse;
		public ufbx_material_map indirect_specular;
		public ufbx_material_map normal_map;
		public ufbx_material_map tangent_map;
		public ufbx_material_map displacement_map;
		public ufbx_material_map matte_factor;
		public ufbx_material_map matte_color;
		public ufbx_material_map ambient_occlusion;
		public ufbx_material_map glossiness;
		public ufbx_material_map coat_glossiness;
		public ufbx_material_map transmission_glossiness;
	}

	[CRepr]
	public struct ufbx_material_features
	{
		public ufbx_material_feature_info pbr;
		public ufbx_material_feature_info metalness;
		public ufbx_material_feature_info diffuse;
		public ufbx_material_feature_info specular;
		public ufbx_material_feature_info emission;
		public ufbx_material_feature_info transmission;
		public ufbx_material_feature_info coat;
		public ufbx_material_feature_info sheen;
		public ufbx_material_feature_info opacity;
		public ufbx_material_feature_info ambient_occlusion;
		public ufbx_material_feature_info matte;
		public ufbx_material_feature_info unlit;
		public ufbx_material_feature_info ior;
		public ufbx_material_feature_info diffuse_roughness;
		public ufbx_material_feature_info transmission_roughness;
		public ufbx_material_feature_info thin_walled;
		public ufbx_material_feature_info caustics;
		public ufbx_material_feature_info exit_to_background;
		public ufbx_material_feature_info internal_reflections;
		public ufbx_material_feature_info double_sided;
		public ufbx_material_feature_info roughness_as_glossiness;
		public ufbx_material_feature_info coat_roughness_as_glossiness;
		public ufbx_material_feature_info transmission_roughness_as_glossiness;
	}

	[CRepr]
	public struct ufbx_texture_layer
	{
		public ufbx_texture* texture;
		public ufbx_blend_mode blend_mode;
		public ufbx_real alpha;
	}

	[CRepr]
	public struct ufbx_texture_layer_list
	{
		public ufbx_texture_layer* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_shader_texture_input
	{
		public ufbx_string name;
		[Union]
		public using struct
		{
			public ufbx_real value_real;
			public ufbx_vec2 value_vec2;
			public ufbx_vec3 value_vec3;
			public ufbx_vec4 value_vec4;
		};
		public int64 value_int;
		public ufbx_string value_str;
		public ufbx_blob value_blob;
		public ufbx_texture* texture;
		public int64 texture_output_index;
		public bool texture_enabled;
		public ufbx_prop* prop;
		public ufbx_prop* texture_prop;
		public ufbx_prop* texture_enabled_prop;
	}

	[CRepr]
	public struct ufbx_shader_texture_input_list
	{
		public ufbx_shader_texture_input* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_shader_texture
	{
		public ufbx_shader_texture_type type;
		public ufbx_string shader_name;
		public uint64 shader_type_id;
		public ufbx_shader_texture_input_list inputs;
		public ufbx_string shader_source;
		public ufbx_blob raw_shader_source;
		public ufbx_texture* main_texture;
		public int64 main_texture_output_index;
		public ufbx_string prop_prefix;
	}

	[CRepr]
	public struct ufbx_texture_file
	{
		public uint32 index;
		public ufbx_string filename;
		public ufbx_string absolute_filename;
		public ufbx_string relative_filename;
		public ufbx_blob raw_filename;
		public ufbx_blob raw_absolute_filename;
		public ufbx_blob raw_relative_filename;
		public ufbx_blob content;
	}

	[CRepr]
	public struct ufbx_texture_file_list
	{
		public ufbx_texture_file* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_shader_prop_binding
	{
		public ufbx_string shader_prop;
		public ufbx_string material_prop;
	}

	[CRepr]
	public struct ufbx_shader_prop_binding_list
	{
		public ufbx_shader_prop_binding* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_tangent
	{
		public float dx;
		public float dy;
	}

	[CRepr]
	public struct ufbx_keyframe
	{
		public double time;
		public ufbx_real value;
		public ufbx_interpolation interpolation;
		public ufbx_tangent left;
		public ufbx_tangent right;
	}

	[CRepr]
	public struct ufbx_keyframe_list
	{
		public ufbx_keyframe* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_extrapolation
	{
		public ufbx_extrapolation_mode mode;
		public int32 repeat_count;
	}

	[CRepr]
	public struct ufbx_prop_override
	{
		public uint32 element_id;
		public uint32 _internal_key;
		public ufbx_string prop_name;
		public ufbx_vec4 value;
		public ufbx_string value_str;
		public int64 value_int;
	}

	[CRepr]
	public struct ufbx_prop_override_list
	{
		public ufbx_prop_override* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_transform_override
	{
		public uint32 node_id;
		public ufbx_transform transform;
	}

	[CRepr]
	public struct ufbx_transform_override_list
	{
		public ufbx_transform_override* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_anim
	{
		public double time_begin;
		public double time_end;
		public ufbx_anim_layer_list layers;
		public ufbx_real_list override_layer_weights;
		public ufbx_prop_override_list prop_overrides;
		public ufbx_transform_override_list transform_overrides;
		public bool ignore_connections;
		public bool custom;
	}

	[CRepr]
	public struct ufbx_anim_prop
	{
		public ufbx_element* element;
		public uint32 _internal_key;
		public ufbx_string prop_name;
		public ufbx_anim_value* anim_value;
	}

	[CRepr]
	public struct ufbx_anim_prop_list
	{
		public ufbx_anim_prop* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_constraint_target
	{
		public ufbx_node* node;
		public ufbx_real weight;
		public ufbx_transform transform;
	}

	[CRepr]
	public struct ufbx_constraint_target_list
	{
		public ufbx_constraint_target* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_bone_pose
	{
		public ufbx_node* bone_node;
		public ufbx_matrix bone_to_world;
		public ufbx_matrix bone_to_parent;
	}

	[CRepr]
	public struct ufbx_bone_pose_list
	{
		public ufbx_bone_pose* data;
		public uint count;
	}

	// -- Element structs --

	[CRepr]
	public struct ufbx_unknown
	{
		public ufbx_element element;
		public ufbx_string type;
		public ufbx_string super_type;
		public ufbx_string sub_type;
	}

	[CRepr]
	public struct ufbx_node
	{
		public ufbx_element element;

		// Node hierarchy
		public ufbx_node* parent;
		public ufbx_node_list children;

		// Common attached element type and typed pointers
		public ufbx_mesh* mesh;
		public ufbx_light* light;
		public ufbx_camera* camera;
		public ufbx_bone* bone;

		// Less common attributes
		public ufbx_element* attrib;

		// Geometry transform helper
		public ufbx_node* geometry_transform_helper;

		// Scale helper
		public ufbx_node* scale_helper;

		// Attrib type
		public ufbx_element_type attrib_type;

		// All attached attribute elements
		public ufbx_element_list all_attribs;

		// Transforms
		public ufbx_inherit_mode inherit_mode;
		public ufbx_inherit_mode original_inherit_mode;
		public ufbx_transform local_transform;
		public ufbx_transform geometry_transform;

		// Combined scale
		public ufbx_vec3 inherit_scale;

		// Inherit scale node
		public ufbx_node* inherit_scale_node;

		// Euler angles
		public ufbx_rotation_order rotation_order;
		public ufbx_vec3 euler_rotation;

		// Matrices
		public ufbx_matrix node_to_parent;
		public ufbx_matrix node_to_world;
		public ufbx_matrix geometry_to_node;
		public ufbx_matrix geometry_to_world;
		public ufbx_matrix unscaled_node_to_world;

		// Adjustment fields
		public ufbx_vec3 adjust_pre_translation;
		public ufbx_quat adjust_pre_rotation;
		public ufbx_real adjust_pre_scale;
		public ufbx_quat adjust_post_rotation;
		public ufbx_real adjust_post_scale;
		public ufbx_real adjust_translation_scale;
		public ufbx_mirror_axis adjust_mirror_axis;

		// Materials
		public ufbx_material_list materials;

		// Bind pose
		public ufbx_pose* bind_pose;

		// Flags
		public bool visible;
		public bool is_root;
		public bool has_geometry_transform;
		public bool has_adjust_transform;
		public bool has_root_adjust_transform;
		public bool is_geometry_transform_helper;
		public bool is_scale_helper;
		public bool is_scale_compensate_parent;

		// Depth
		public uint32 node_depth;
	}

	[CRepr]
	public struct ufbx_mesh
	{
		public ufbx_element element;

		// Counts
		public uint num_vertices;
		public uint num_indices;
		public uint num_faces;
		public uint num_triangles;
		public uint num_edges;
		public uint max_face_triangles;
		public uint num_empty_faces;
		public uint num_point_faces;
		public uint num_line_faces;

		// Faces and per-face data
		public ufbx_face_list faces;
		public ufbx_bool_list face_smoothing;
		public ufbx_uint32_list face_material;
		public ufbx_uint32_list face_group;
		public ufbx_bool_list face_hole;

		// Edges and per-edge data
		public ufbx_edge_list edges;
		public ufbx_bool_list edge_smoothing;
		public ufbx_real_list edge_crease;
		public ufbx_bool_list edge_visibility;

		// Vertices
		public ufbx_uint32_list vertex_indices;
		public ufbx_vec3_list vertices;
		public ufbx_uint32_list vertex_first_index;

		// Vertex attributes
		public ufbx_vertex_vec3 vertex_position;
		public ufbx_vertex_vec3 vertex_normal;
		public ufbx_vertex_vec2 vertex_uv;
		public ufbx_vertex_vec3 vertex_tangent;
		public ufbx_vertex_vec3 vertex_bitangent;
		public ufbx_vertex_vec4 vertex_color;
		public ufbx_vertex_real vertex_crease;

		// UV/color sets
		public ufbx_uv_set_list uv_sets;
		public ufbx_color_set_list color_sets;

		// Materials
		public ufbx_material_list materials;

		// Face groups
		public ufbx_face_group_list face_groups;

		// Mesh parts
		public ufbx_mesh_part_list material_parts;
		public ufbx_mesh_part_list face_group_parts;
		public ufbx_uint32_list material_part_usage_order;

		// Skinned positions
		public bool skinned_is_local;
		public ufbx_vertex_vec3 skinned_position;
		public ufbx_vertex_vec3 skinned_normal;

		// Deformers
		public ufbx_skin_deformer_list skin_deformers;
		public ufbx_blend_deformer_list blend_deformers;
		public ufbx_cache_deformer_list cache_deformers;
		public ufbx_element_list all_deformers;

		// Subdivision
		public uint32 subdivision_preview_levels;
		public uint32 subdivision_render_levels;
		public ufbx_subdivision_display_mode subdivision_display_mode;
		public ufbx_subdivision_boundary subdivision_boundary;
		public ufbx_subdivision_boundary subdivision_uv_boundary;

		// Flags
		public bool reversed_winding;
		public bool generated_normals;
		public bool subdivision_evaluated;
		public ufbx_subdivision_result* subdivision_result;
		public bool from_tessellated_nurbs;
	}

	[CRepr]
	public struct ufbx_light
	{
		public ufbx_element element;

		public ufbx_vec3 color;
		public ufbx_real intensity;
		public ufbx_vec3 local_direction;
		public ufbx_light_type type;
		public ufbx_light_decay decay;
		public ufbx_light_area_shape area_shape;
		public ufbx_real inner_angle;
		public ufbx_real outer_angle;
		public bool cast_light;
		public bool cast_shadows;
	}

	[CRepr]
	public struct ufbx_camera
	{
		public ufbx_element element;

		public ufbx_projection_mode projection_mode;
		public bool resolution_is_pixels;
		public ufbx_vec2 resolution;
		public ufbx_vec2 field_of_view_deg;
		public ufbx_vec2 field_of_view_tan;
		public ufbx_real orthographic_extent;
		public ufbx_vec2 orthographic_size;
		public ufbx_vec2 projection_plane;
		public ufbx_real aspect_ratio;
		public ufbx_real near_plane;
		public ufbx_real far_plane;
		public ufbx_coordinate_axes projection_axes;
		public ufbx_aspect_mode aspect_mode;
		public ufbx_aperture_mode aperture_mode;
		public ufbx_gate_fit gate_fit;
		public ufbx_aperture_format aperture_format;
		public ufbx_real focal_length_mm;
		public ufbx_vec2 film_size_inch;
		public ufbx_vec2 aperture_size_inch;
		public ufbx_real squeeze_ratio;
	}

	[CRepr]
	public struct ufbx_bone
	{
		public ufbx_element element;

		public ufbx_real radius;
		public ufbx_real relative_length;
		public bool is_root;
	}

	[CRepr]
	public struct ufbx_empty
	{
		public ufbx_element element;
	}

	[CRepr]
	public struct ufbx_line_curve
	{
		public ufbx_element element;

		public ufbx_vec3 color;
		public ufbx_vec3_list control_points;
		public ufbx_uint32_list point_indices;
		public ufbx_line_segment_list segments;
		public bool from_tessellated_nurbs;
	}

	[CRepr]
	public struct ufbx_nurbs_curve
	{
		public ufbx_element element;

		public ufbx_nurbs_basis basis;
		public ufbx_vec4_list control_points;
	}

	[CRepr]
	public struct ufbx_nurbs_surface
	{
		public ufbx_element element;

		public ufbx_nurbs_basis basis_u;
		public ufbx_nurbs_basis basis_v;
		public uint num_control_points_u;
		public uint num_control_points_v;
		public ufbx_vec4_list control_points;
		public uint32 span_subdivision_u;
		public uint32 span_subdivision_v;
		public bool flip_normals;
		public ufbx_material* material;
	}

	[CRepr]
	public struct ufbx_nurbs_trim_surface
	{
		public ufbx_element element;
	}

	[CRepr]
	public struct ufbx_nurbs_trim_boundary
	{
		public ufbx_element element;
	}

	[CRepr]
	public struct ufbx_procedural_geometry
	{
		public ufbx_element element;
	}

	[CRepr]
	public struct ufbx_stereo_camera
	{
		public ufbx_element element;

		public ufbx_camera* left;
		public ufbx_camera* right;
	}

	[CRepr]
	public struct ufbx_camera_switcher
	{
		public ufbx_element element;
	}

	[CRepr]
	public struct ufbx_marker
	{
		public ufbx_element element;

		public ufbx_marker_type type;
	}

	[CRepr]
	public struct ufbx_lod_group
	{
		public ufbx_element element;

		public bool relative_distances;
		public ufbx_lod_level_list lod_levels;
		public bool ignore_parent_transform;
		public bool use_distance_limit;
		public ufbx_real distance_limit_min;
		public ufbx_real distance_limit_max;
	}

	[CRepr]
	public struct ufbx_skin_deformer
	{
		public ufbx_element element;

		public ufbx_skinning_method skinning_method;
		public ufbx_skin_cluster_list clusters;
		public ufbx_skin_vertex_list vertices;
		public ufbx_skin_weight_list weights;
		public uint max_weights_per_vertex;
		public uint num_dq_weights;
		public ufbx_uint32_list dq_vertices;
		public ufbx_real_list dq_weights;
	}

	[CRepr]
	public struct ufbx_skin_cluster
	{
		public ufbx_element element;

		public ufbx_node* bone_node;
		public ufbx_matrix geometry_to_bone;
		public ufbx_matrix mesh_node_to_bone;
		public ufbx_matrix bind_to_world;
		public ufbx_matrix geometry_to_world;
		public ufbx_transform geometry_to_world_transform;
		public uint num_weights;
		public ufbx_uint32_list vertices;
		public ufbx_real_list weights;
	}

	[CRepr]
	public struct ufbx_blend_deformer
	{
		public ufbx_element element;

		public ufbx_blend_channel_list channels;
	}

	[CRepr]
	public struct ufbx_blend_channel
	{
		public ufbx_element element;

		public ufbx_real weight;
		public ufbx_blend_keyframe_list keyframes;
		public ufbx_blend_shape* target_shape;
	}

	[CRepr]
	public struct ufbx_blend_shape
	{
		public ufbx_element element;

		public uint num_offsets;
		public ufbx_uint32_list offset_vertices;
		public ufbx_vec3_list position_offsets;
		public ufbx_vec3_list normal_offsets;
		public ufbx_real_list offset_weights;
	}

	[CRepr]
	public struct ufbx_cache_deformer
	{
		public ufbx_element element;

		public ufbx_string channel;
		public ufbx_cache_file* file;
		public ufbx_geometry_cache* external_cache;
		public ufbx_cache_channel* external_channel;
	}

	[CRepr]
	public struct ufbx_cache_file
	{
		public ufbx_element element;

		public ufbx_string filename;
		public ufbx_string absolute_filename;
		public ufbx_string relative_filename;
		public ufbx_blob raw_filename;
		public ufbx_blob raw_absolute_filename;
		public ufbx_blob raw_relative_filename;
		public ufbx_cache_file_format format;
		public ufbx_geometry_cache* external_cache;
	}

	[CRepr]
	public struct ufbx_material
	{
		public ufbx_element element;

		public ufbx_material_fbx_maps fbx;
		public ufbx_material_pbr_maps pbr;
		public ufbx_material_features features;
		public ufbx_shader_type shader_type;
		public ufbx_shader* shader;
		public ufbx_string shading_model_name;
		public ufbx_string shader_prop_prefix;
		public ufbx_material_texture_list textures;
	}

	[CRepr]
	public struct ufbx_texture
	{
		public ufbx_element element;

		public ufbx_texture_type type;

		// FILE: Paths
		public ufbx_string filename;
		public ufbx_string absolute_filename;
		public ufbx_string relative_filename;
		public ufbx_blob raw_filename;
		public ufbx_blob raw_absolute_filename;
		public ufbx_blob raw_relative_filename;

		// FILE: Content
		public ufbx_blob content;

		// FILE: Video
		public ufbx_video* video;

		// FILE: Index
		public uint32 file_index;
		public bool has_file;

		// LAYERED: Layers
		public ufbx_texture_layer_list layers;

		// SHADER: Shader
		public ufbx_shader_texture* shader;

		// File textures
		public ufbx_texture_list file_textures;

		// UV set
		public ufbx_string uv_set;

		// Wrapping
		public ufbx_wrap_mode wrap_u;
		public ufbx_wrap_mode wrap_v;

		// UV transform
		public bool has_uv_transform;
		public ufbx_transform uv_transform;
		public ufbx_matrix texture_to_uv;
		public ufbx_matrix uv_to_texture;
	}

	[CRepr]
	public struct ufbx_video
	{
		public ufbx_element element;

		public ufbx_string filename;
		public ufbx_string absolute_filename;
		public ufbx_string relative_filename;
		public ufbx_blob raw_filename;
		public ufbx_blob raw_absolute_filename;
		public ufbx_blob raw_relative_filename;
		public ufbx_blob content;
	}

	[CRepr]
	public struct ufbx_shader
	{
		public ufbx_element element;

		public ufbx_shader_type type;
		public ufbx_shader_binding_list bindings;
	}

	[CRepr]
	public struct ufbx_shader_binding
	{
		public ufbx_element element;

		public ufbx_shader_prop_binding_list prop_bindings;
	}

	[CRepr]
	public struct ufbx_anim_stack
	{
		public ufbx_element element;

		public double time_begin;
		public double time_end;
		public ufbx_anim_layer_list layers;
		public ufbx_anim* anim;
	}

	[CRepr]
	public struct ufbx_anim_layer
	{
		public ufbx_element element;

		public ufbx_real weight;
		public bool weight_is_animated;
		public bool blended;
		public bool additive;
		public bool compose_rotation;
		public bool compose_scale;
		public ufbx_anim_value_list anim_values;
		public ufbx_anim_prop_list anim_props;
		public ufbx_anim* anim;
		public uint32 _min_element_id;
		public uint32 _max_element_id;
		public uint32[4] _element_id_bitmask;
	}

	[CRepr]
	public struct ufbx_anim_value
	{
		public ufbx_element element;

		public ufbx_vec3 default_value;
		public ufbx_anim_curve*[3] curves;
	}

	[CRepr]
	public struct ufbx_anim_curve
	{
		public ufbx_element element;

		public ufbx_keyframe_list keyframes;
		public ufbx_extrapolation pre_extrapolation;
		public ufbx_extrapolation post_extrapolation;
		public ufbx_real min_value;
		public ufbx_real max_value;
		public double min_time;
		public double max_time;
	}

	[CRepr]
	public struct ufbx_display_layer
	{
		public ufbx_element element;

		public ufbx_node_list nodes;
		public bool visible;
		public bool frozen;
		public ufbx_vec3 ui_color;
	}

	[CRepr]
	public struct ufbx_selection_set
	{
		public ufbx_element element;

		public ufbx_selection_node_list nodes;
	}

	[CRepr]
	public struct ufbx_selection_node
	{
		public ufbx_element element;

		public ufbx_node* target_node;
		public ufbx_mesh* target_mesh;
		public bool include_node;
		public ufbx_uint32_list vertices;
		public ufbx_uint32_list edges;
		public ufbx_uint32_list faces;
	}

	[CRepr]
	public struct ufbx_character
	{
		public ufbx_element element;
	}

	[CRepr]
	public struct ufbx_constraint
	{
		public ufbx_element element;

		public ufbx_constraint_type type;
		public ufbx_string type_name;
		public ufbx_node* node;
		public ufbx_constraint_target_list targets;
		public ufbx_real weight;
		public bool active;
		public bool[3] constrain_translation;
		public bool[3] constrain_rotation;
		public bool[3] constrain_scale;
		public ufbx_transform transform_offset;
		public ufbx_vec3 aim_vector;
		public ufbx_constraint_aim_up_type aim_up_type;
		public ufbx_node* aim_up_node;
		public ufbx_vec3 aim_up_vector;
		public ufbx_node* ik_effector;
		public ufbx_node* ik_end_node;
		public ufbx_vec3 ik_pole_vector;
	}

	[CRepr]
	public struct ufbx_audio_layer
	{
		public ufbx_element element;

		public ufbx_audio_clip_list clips;
	}

	[CRepr]
	public struct ufbx_audio_clip
	{
		public ufbx_element element;

		public ufbx_string filename;
		public ufbx_string absolute_filename;
		public ufbx_string relative_filename;
		public ufbx_blob raw_filename;
		public ufbx_blob raw_absolute_filename;
		public ufbx_blob raw_relative_filename;
		public ufbx_blob content;
	}

	[CRepr]
	public struct ufbx_pose
	{
		public ufbx_element element;

		public bool is_bind_pose;
		public ufbx_bone_pose_list bone_poses;
	}

	[CRepr]
	public struct ufbx_metadata_object
	{
		public ufbx_element element;
	}

static{
	public const uint32 UFBX_ERROR_STACK_MAX_DEPTH = 8;
	public const uint32 UFBX_ERROR_INFO_LENGTH = 256;
	public const uint32 UFBX_PANIC_MESSAGE_LENGTH = 256;
	public const uint32 UFBX_ELEMENT_TYPE_COUNT = 42;
	public const uint32 UFBX_MATERIAL_FBX_MAP_COUNT = 20;
	public const uint32 UFBX_MATERIAL_PBR_MAP_COUNT = 56;
	public const uint32 UFBX_MATERIAL_FEATURE_COUNT = 23;
	public const uint32 UFBX_WARNING_TYPE_COUNT = 15;
}

	// -- Named elements

	[CRepr]
	public struct ufbx_name_element
	{
		public ufbx_string name;
		public ufbx_element_type type;
		public uint32 _internal_key;
		public ufbx_element* element;
	}

	[CRepr]
	public struct ufbx_name_element_list
	{
		public ufbx_name_element* data;
		public uint count;
	}

	// -- Scene

	public enum ufbx_exporter : int32
	{
		UFBX_EXPORTER_UNKNOWN,
		UFBX_EXPORTER_FBX_SDK,
		UFBX_EXPORTER_BLENDER_BINARY,
		UFBX_EXPORTER_BLENDER_ASCII,
		UFBX_EXPORTER_MOTION_BUILDER,
	}

	[CRepr]
	public struct ufbx_application
	{
		public ufbx_string vendor;
		public ufbx_string name;
		public ufbx_string version;
	}

	public enum ufbx_file_format : int32
	{
		UFBX_FILE_FORMAT_UNKNOWN,
		UFBX_FILE_FORMAT_FBX,
		UFBX_FILE_FORMAT_OBJ,
		UFBX_FILE_FORMAT_MTL,
	}

	[AllowDuplicates]
	public enum ufbx_warning_type : int32
	{
		UFBX_WARNING_MISSING_EXTERNAL_FILE,
		UFBX_WARNING_IMPLICIT_MTL,
		UFBX_WARNING_TRUNCATED_ARRAY,
		UFBX_WARNING_MISSING_GEOMETRY_DATA,
		UFBX_WARNING_DUPLICATE_CONNECTION,
		UFBX_WARNING_BAD_VERTEX_W_ATTRIBUTE,
		UFBX_WARNING_MISSING_POLYGON_MAPPING,
		UFBX_WARNING_UNSUPPORTED_VERSION,
		UFBX_WARNING_INDEX_CLAMPED,
		UFBX_WARNING_BAD_UNICODE,
		UFBX_WARNING_BAD_BASE64_CONTENT,
		UFBX_WARNING_BAD_ELEMENT_CONNECTED_TO_ROOT,
		UFBX_WARNING_DUPLICATE_OBJECT_ID,
		UFBX_WARNING_EMPTY_FACE_REMOVED,
		UFBX_WARNING_UNKNOWN_OBJ_DIRECTIVE,

		UFBX_WARNING_TYPE_FIRST_DEDUPLICATED = UFBX_WARNING_INDEX_CLAMPED,
	}

	[CRepr]
	public struct ufbx_warning
	{
		public ufbx_warning_type type;
		public ufbx_string description;
		public uint32 element_id;
		public uint count;
	}

	[CRepr]
	public struct ufbx_warning_list
	{
		public ufbx_warning* data;
		public uint count;
	}

	public enum ufbx_thumbnail_format : int32
	{
		UFBX_THUMBNAIL_FORMAT_UNKNOWN,
		UFBX_THUMBNAIL_FORMAT_RGB_24,
		UFBX_THUMBNAIL_FORMAT_RGBA_32,
	}

	public enum ufbx_space_conversion : int32
	{
		UFBX_SPACE_CONVERSION_TRANSFORM_ROOT,
		UFBX_SPACE_CONVERSION_ADJUST_TRANSFORMS,
		UFBX_SPACE_CONVERSION_MODIFY_GEOMETRY,
	}

	public enum ufbx_geometry_transform_handling : int32
	{
		UFBX_GEOMETRY_TRANSFORM_HANDLING_PRESERVE,
		UFBX_GEOMETRY_TRANSFORM_HANDLING_HELPER_NODES,
		UFBX_GEOMETRY_TRANSFORM_HANDLING_MODIFY_GEOMETRY,
		UFBX_GEOMETRY_TRANSFORM_HANDLING_MODIFY_GEOMETRY_NO_FALLBACK,
	}

	public enum ufbx_inherit_mode_handling : int32
	{
		UFBX_INHERIT_MODE_HANDLING_PRESERVE,
		UFBX_INHERIT_MODE_HANDLING_HELPER_NODES,
		UFBX_INHERIT_MODE_HANDLING_COMPENSATE,
		UFBX_INHERIT_MODE_HANDLING_COMPENSATE_NO_FALLBACK,
		UFBX_INHERIT_MODE_HANDLING_IGNORE,
	}

	public enum ufbx_pivot_handling : int32
	{
		UFBX_PIVOT_HANDLING_RETAIN,
		UFBX_PIVOT_HANDLING_ADJUST_TO_PIVOT,
		UFBX_PIVOT_HANDLING_ADJUST_TO_ROTATION_PIVOT,
	}

	[CRepr]
	public struct ufbx_thumbnail
	{
		public ufbx_props props;
		public uint32 width;
		public uint32 height;
		public ufbx_thumbnail_format format;
		public ufbx_blob data;
	}

	[CRepr]
	public struct ufbx_metadata
	{
		public ufbx_warning_list warnings;
		public bool ascii;
		public uint32 version;
		public ufbx_file_format file_format;
		public bool may_contain_no_index;
		public bool may_contain_missing_vertex_position;
		public bool may_contain_broken_elements;
		public bool is_unsafe;
		public bool[15] has_warning;
		public ufbx_string creator;
		public bool big_endian;
		public ufbx_string filename;
		public ufbx_string relative_root;
		public ufbx_blob raw_filename;
		public ufbx_blob raw_relative_root;
		public ufbx_exporter exporter;
		public uint32 exporter_version;
		public ufbx_props scene_props;
		public ufbx_application original_application;
		public ufbx_application latest_application;
		public ufbx_thumbnail thumbnail;
		public bool geometry_ignored;
		public bool animation_ignored;
		public bool embedded_ignored;
		public uint max_face_triangles;
		public uint result_memory_used;
		public uint temp_memory_used;
		public uint result_allocs;
		public uint temp_allocs;
		public uint element_buffer_size;
		public uint num_shader_textures;
		public double bone_prop_size_unit;
		public bool bone_prop_limb_length_relative;
		public double ortho_size_unit;
		public int64 ktime_second;
		public ufbx_string original_file_path;
		public ufbx_blob raw_original_file_path;
		public ufbx_space_conversion space_conversion;
		public ufbx_geometry_transform_handling geometry_transform_handling;
		public ufbx_inherit_mode_handling inherit_mode_handling;
		public ufbx_pivot_handling pivot_handling;
		public ufbx_mirror_axis handedness_conversion_axis;
		public ufbx_quat root_rotation;
		public double root_scale;
		public ufbx_mirror_axis mirror_axis;
		public double geometry_scale;
	}

	public enum ufbx_time_mode : int32
	{
		UFBX_TIME_MODE_DEFAULT,
		UFBX_TIME_MODE_120_FPS,
		UFBX_TIME_MODE_100_FPS,
		UFBX_TIME_MODE_60_FPS,
		UFBX_TIME_MODE_50_FPS,
		UFBX_TIME_MODE_48_FPS,
		UFBX_TIME_MODE_30_FPS,
		UFBX_TIME_MODE_30_FPS_DROP,
		UFBX_TIME_MODE_NTSC_DROP_FRAME,
		UFBX_TIME_MODE_NTSC_FULL_FRAME,
		UFBX_TIME_MODE_PAL,
		UFBX_TIME_MODE_24_FPS,
		UFBX_TIME_MODE_1000_FPS,
		UFBX_TIME_MODE_FILM_FULL_FRAME,
		UFBX_TIME_MODE_CUSTOM,
		UFBX_TIME_MODE_96_FPS,
		UFBX_TIME_MODE_72_FPS,
		UFBX_TIME_MODE_59_94_FPS,
	}

	public enum ufbx_time_protocol : int32
	{
		UFBX_TIME_PROTOCOL_SMPTE,
		UFBX_TIME_PROTOCOL_FRAME_COUNT,
		UFBX_TIME_PROTOCOL_DEFAULT,
	}

	public enum ufbx_snap_mode : int32
	{
		UFBX_SNAP_MODE_NONE,
		UFBX_SNAP_MODE_SNAP,
		UFBX_SNAP_MODE_PLAY,
		UFBX_SNAP_MODE_SNAP_AND_PLAY,
	}

	[CRepr]
	public struct ufbx_scene_settings
	{
		public ufbx_props props;
		public ufbx_coordinate_axes axes;
		public double unit_meters;
		public double frames_per_second;
		public ufbx_vec3 ambient_color;
		public ufbx_string default_camera;
		public ufbx_time_mode time_mode;
		public ufbx_time_protocol time_protocol;
		public ufbx_snap_mode snap_mode;
		public ufbx_coordinate_axis original_axis_up;
		public double original_unit_meters;
	}

	[CRepr]
	public struct ufbx_scene
	{
		public ufbx_metadata metadata;
		public ufbx_scene_settings settings;
		public ufbx_node* root_node;
		public ufbx_anim* anim;

		// Named element lists (union with elements_by_type)
		public ufbx_unknown_list unknowns;
		public ufbx_node_list nodes;
		public ufbx_mesh_list meshes;
		public ufbx_light_list lights;
		public ufbx_camera_list cameras;
		public ufbx_bone_list bones;
		public ufbx_empty_list empties;
		public ufbx_line_curve_list line_curves;
		public ufbx_nurbs_curve_list nurbs_curves;
		public ufbx_nurbs_surface_list nurbs_surfaces;
		public ufbx_nurbs_trim_surface_list nurbs_trim_surfaces;
		public ufbx_nurbs_trim_boundary_list nurbs_trim_boundaries;
		public ufbx_procedural_geometry_list procedural_geometries;
		public ufbx_stereo_camera_list stereo_cameras;
		public ufbx_camera_switcher_list camera_switchers;
		public ufbx_marker_list markers;
		public ufbx_lod_group_list lod_groups;
		public ufbx_skin_deformer_list skin_deformers;
		public ufbx_skin_cluster_list skin_clusters;
		public ufbx_blend_deformer_list blend_deformers;
		public ufbx_blend_channel_list blend_channels;
		public ufbx_blend_shape_list blend_shapes;
		public ufbx_cache_deformer_list cache_deformers;
		public ufbx_cache_file_list cache_files;
		public ufbx_material_list materials;
		public ufbx_texture_list textures;
		public ufbx_video_list videos;
		public ufbx_shader_list shaders;
		public ufbx_shader_binding_list shader_bindings;
		public ufbx_anim_stack_list anim_stacks;
		public ufbx_anim_layer_list anim_layers;
		public ufbx_anim_value_list anim_values;
		public ufbx_anim_curve_list anim_curves;
		public ufbx_display_layer_list display_layers;
		public ufbx_selection_set_list selection_sets;
		public ufbx_selection_node_list selection_nodes;
		public ufbx_character_list characters;
		public ufbx_constraint_list constraints;
		public ufbx_audio_layer_list audio_layers;
		public ufbx_audio_clip_list audio_clips;
		public ufbx_pose_list poses;
		public ufbx_metadata_object_list metadata_objects;

		public ufbx_texture_file_list texture_files;
		public ufbx_element_list elements;
		public ufbx_connection_list connections_src;
		public ufbx_connection_list connections_dst;
		public ufbx_name_element_list elements_by_name;
		public ufbx_dom_node* dom_root;
	}

	// -- Curves

	[CRepr]
	public struct ufbx_curve_point
	{
		public bool valid;
		public ufbx_vec3 position;
		public ufbx_vec3 derivative;
	}

	[CRepr]
	public struct ufbx_surface_point
	{
		public bool valid;
		public ufbx_vec3 position;
		public ufbx_vec3 derivative_u;
		public ufbx_vec3 derivative_v;
	}

	// -- Mesh topology

	public enum ufbx_topo_flags : uint32
	{
		UFBX_TOPO_NON_MANIFOLD = 0x1,
	}

	[CRepr]
	public struct ufbx_topo_edge
	{
		public uint32 index;
		public uint32 next;
		public uint32 prev;
		public uint32 twin;
		public uint32 face;
		public uint32 edge;
		public ufbx_topo_flags flags;
	}

	[CRepr]
	public struct ufbx_vertex_stream
	{
		public void* data;
		public uint vertex_count;
		public uint vertex_size;
	}

	// -- Function pointer typedefs

	public typealias ufbx_alloc_fn = function void*(void* user, uint size);
	public typealias ufbx_realloc_fn = function void*(void* user, void* old_ptr, uint old_size, uint new_size);
	public typealias ufbx_free_fn = function void(void* user, void* ptr, uint size);
	public typealias ufbx_free_allocator_fn = function void(void* user);
	public typealias ufbx_read_fn = function uint(void* user, void* data, uint size);
	public typealias ufbx_skip_fn = function bool(void* user, uint size);
	public typealias ufbx_size_fn = function uint64(void* user);
	public typealias ufbx_close_fn = function void(void* user);
	public typealias ufbx_open_file_fn = function bool(void* user, ufbx_stream* stream, char8* path, uint path_len, ufbx_open_file_info* info);
	public typealias ufbx_close_memory_fn = function void(void* user, void* data, uint data_size);
	public typealias ufbx_progress_fn = function ufbx_progress_result(void* user, ufbx_progress* progress);
	public typealias ufbx_thread_pool_init_fn = function bool(void* user, uint ctx, ufbx_thread_pool_info* info);
	public typealias ufbx_thread_pool_run_fn = function void(void* user, uint ctx, uint32 group, uint32 start_index, uint32 count);
	public typealias ufbx_thread_pool_wait_fn = function void(void* user, uint ctx, uint32 group, uint32 max_index);
	public typealias ufbx_thread_pool_free_fn = function void(void* user, uint ctx);

	// -- Memory callbacks

	[CRepr]
	public struct ufbx_allocator
	{
		public ufbx_alloc_fn alloc_fn;
		public ufbx_realloc_fn realloc_fn;
		public ufbx_free_fn free_fn;
		public ufbx_free_allocator_fn free_allocator_fn;
		public void* user;
	}

	[CRepr]
	public struct ufbx_allocator_opts
	{
		public ufbx_allocator allocator;
		public uint memory_limit;
		public uint allocation_limit;
		public uint huge_threshold;
		public uint max_chunk_size;
	}

	// -- IO callbacks

	[CRepr]
	public struct ufbx_stream
	{
		public ufbx_read_fn read_fn;
		public ufbx_skip_fn skip_fn;
		public ufbx_size_fn size_fn;
		public ufbx_close_fn close_fn;
		public void* user;
	}

	public enum ufbx_open_file_type : int32
	{
		UFBX_OPEN_FILE_MAIN_MODEL,
		UFBX_OPEN_FILE_GEOMETRY_CACHE,
		UFBX_OPEN_FILE_OBJ_MTL,
	}

	public typealias ufbx_open_file_context = uint;

	[CRepr]
	public struct ufbx_open_file_info
	{
		public ufbx_open_file_context context;
		public ufbx_open_file_type type;
		public ufbx_blob original_filename;
	}

	[CRepr]
	public struct ufbx_open_file_cb
	{
		public ufbx_open_file_fn fn;
		public void* user;
	}

	[CRepr]
	public struct ufbx_open_file_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts allocator;
		public bool filename_null_terminated;
		public uint32 _end_zero;
	}

	[CRepr]
	public struct ufbx_close_memory_cb
	{
		public ufbx_close_memory_fn fn;
		public void* user;
	}

	[CRepr]
	public struct ufbx_open_memory_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts allocator;
		public bool no_copy;
		public ufbx_close_memory_cb close_cb;
		public uint32 _end_zero;
	}

	// -- Errors

	[CRepr]
	public struct ufbx_error_frame
	{
		public uint32 source_line;
		public ufbx_string @function;
		public ufbx_string description;
	}

	public enum ufbx_error_type : int32
	{
		UFBX_ERROR_NONE,
		UFBX_ERROR_UNKNOWN,
		UFBX_ERROR_FILE_NOT_FOUND,
		UFBX_ERROR_EMPTY_FILE,
		UFBX_ERROR_EXTERNAL_FILE_NOT_FOUND,
		UFBX_ERROR_OUT_OF_MEMORY,
		UFBX_ERROR_MEMORY_LIMIT,
		UFBX_ERROR_ALLOCATION_LIMIT,
		UFBX_ERROR_TRUNCATED_FILE,
		UFBX_ERROR_IO,
		UFBX_ERROR_CANCELLED,
		UFBX_ERROR_UNRECOGNIZED_FILE_FORMAT,
		UFBX_ERROR_UNINITIALIZED_OPTIONS,
		UFBX_ERROR_ZERO_VERTEX_SIZE,
		UFBX_ERROR_TRUNCATED_VERTEX_STREAM,
		UFBX_ERROR_INVALID_UTF8,
		UFBX_ERROR_FEATURE_DISABLED,
		UFBX_ERROR_BAD_NURBS,
		UFBX_ERROR_BAD_INDEX,
		UFBX_ERROR_NODE_DEPTH_LIMIT,
		UFBX_ERROR_THREADED_ASCII_PARSE,
		UFBX_ERROR_UNSAFE_OPTIONS,
		UFBX_ERROR_DUPLICATE_OVERRIDE,
		UFBX_ERROR_UNSUPPORTED_VERSION,
	}

	[CRepr]
	public struct ufbx_error
	{
		public ufbx_error_type type;
		public ufbx_string description;
		public uint32 stack_size;
		public ufbx_error_frame[8] stack;
		public uint info_length;
		public char8[256] info;
	}

	// -- Progress callbacks

	[CRepr]
	public struct ufbx_progress
	{
		public uint64 bytes_read;
		public uint64 bytes_total;
	}

	public enum ufbx_progress_result : int32
	{
		UFBX_PROGRESS_CONTINUE = 0x100,
		UFBX_PROGRESS_CANCEL = 0x200,
	}

	[CRepr]
	public struct ufbx_progress_cb
	{
		public ufbx_progress_fn fn;
		public void* user;
	}

	// -- Inflate

	[CRepr]
	public struct ufbx_inflate_input
	{
		public uint total_size;
		public void* data;
		public uint data_size;
		public void* buffer;
		public uint buffer_size;
		public ufbx_read_fn read_fn;
		public void* read_user;
		public ufbx_progress_cb progress_cb;
		public uint64 progress_interval_hint;
		public uint64 progress_size_before;
		public uint64 progress_size_after;
		public bool no_header;
		public bool no_checksum;
		public uint internal_fast_bits;
	}

	[CRepr]
	public struct ufbx_inflate_retain
	{
		public bool initialized;
		public uint64[1024] data;
	}

	// -- Error handling enums

	public enum ufbx_index_error_handling : int32
	{
		UFBX_INDEX_ERROR_HANDLING_CLAMP,
		UFBX_INDEX_ERROR_HANDLING_NO_INDEX,
		UFBX_INDEX_ERROR_HANDLING_ABORT_LOADING,
		UFBX_INDEX_ERROR_HANDLING_UNSAFE_IGNORE,
	}

	public enum ufbx_unicode_error_handling : int32
	{
		UFBX_UNICODE_ERROR_HANDLING_REPLACEMENT_CHARACTER,
		UFBX_UNICODE_ERROR_HANDLING_UNDERSCORE,
		UFBX_UNICODE_ERROR_HANDLING_QUESTION_MARK,
		UFBX_UNICODE_ERROR_HANDLING_REMOVE,
		UFBX_UNICODE_ERROR_HANDLING_ABORT_LOADING,
		UFBX_UNICODE_ERROR_HANDLING_UNSAFE_IGNORE,
	}

	// -- Baked animation types

	public enum ufbx_baked_key_flags : uint32
	{
		UFBX_BAKED_KEY_STEP_LEFT = 0x1,
		UFBX_BAKED_KEY_STEP_RIGHT = 0x2,
		UFBX_BAKED_KEY_STEP_KEY = 0x4,
		UFBX_BAKED_KEY_KEYFRAME = 0x8,
		UFBX_BAKED_KEY_REDUCED = 0x10,
	}

	[CRepr]
	public struct ufbx_baked_vec3
	{
		public double time;
		public ufbx_vec3 value;
		public ufbx_baked_key_flags flags;
	}

	[CRepr]
	public struct ufbx_baked_vec3_list
	{
		public ufbx_baked_vec3* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_baked_quat
	{
		public double time;
		public ufbx_quat value;
		public ufbx_baked_key_flags flags;
	}

	[CRepr]
	public struct ufbx_baked_quat_list
	{
		public ufbx_baked_quat* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_baked_node
	{
		public uint32 typed_id;
		public uint32 element_id;
		public bool constant_translation;
		public bool constant_rotation;
		public bool constant_scale;
		public ufbx_baked_vec3_list translation_keys;
		public ufbx_baked_quat_list rotation_keys;
		public ufbx_baked_vec3_list scale_keys;
	}

	[CRepr]
	public struct ufbx_baked_node_list
	{
		public ufbx_baked_node* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_baked_prop
	{
		public ufbx_string name;
		public bool constant_value;
		public ufbx_baked_vec3_list keys;
	}

	[CRepr]
	public struct ufbx_baked_prop_list
	{
		public ufbx_baked_prop* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_baked_element
	{
		public uint32 element_id;
		public ufbx_baked_prop_list props;
	}

	[CRepr]
	public struct ufbx_baked_element_list
	{
		public ufbx_baked_element* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_baked_anim_metadata
	{
		public uint result_memory_used;
		public uint temp_memory_used;
		public uint result_allocs;
		public uint temp_allocs;
	}

	[CRepr]
	public struct ufbx_baked_anim
	{
		public ufbx_baked_node_list nodes;
		public ufbx_baked_element_list elements;
		public double playback_time_begin;
		public double playback_time_end;
		public double playback_duration;
		public double key_time_min;
		public double key_time_max;
		public ufbx_baked_anim_metadata metadata;
	}

	// -- Thread API

	public typealias ufbx_thread_pool_context = uint;

	[CRepr]
	public struct ufbx_thread_pool_info
	{
		public uint32 max_concurrent_tasks;
	}

	[CRepr]
	public struct ufbx_thread_pool
	{
		public ufbx_thread_pool_init_fn init_fn;
		public ufbx_thread_pool_run_fn run_fn;
		public ufbx_thread_pool_wait_fn wait_fn;
		public ufbx_thread_pool_free_fn free_fn;
		public void* user;
	}

	[CRepr]
	public struct ufbx_thread_opts
	{
		public ufbx_thread_pool pool;
		public uint num_tasks;
		public uint memory_limit;
	}

	// -- Evaluate flags

	public enum ufbx_evaluate_flags : uint32
	{
		UFBX_EVALUATE_FLAG_NO_EXTRAPOLATION = 0x1,
	}

	// -- Load options

	[CRepr]
	public struct ufbx_load_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public ufbx_thread_opts thread_opts;
		public bool ignore_geometry;
		public bool ignore_animation;
		public bool ignore_embedded;
		public bool ignore_all_content;
		public bool evaluate_skinning;
		public bool evaluate_caches;
		public bool load_external_files;
		public bool ignore_missing_external_files;
		public bool skip_skin_vertices;
		public bool skip_mesh_parts;
		public bool clean_skin_weights;
		public bool use_blender_pbr_material;
		public bool disable_quirks;
		public bool strict;
		public bool force_single_thread_ascii_parsing;
		public bool allow_unsafe;
		public ufbx_index_error_handling index_error_handling;
		public bool connect_broken_elements;
		public bool allow_nodes_out_of_root;
		public bool allow_missing_vertex_position;
		public bool allow_empty_faces;
		public bool generate_missing_normals;
		public bool open_main_file_with_default;
		public char8 path_separator;
		public uint32 node_depth_limit;
		public uint64 file_size_estimate;
		public uint read_buffer_size;
		public ufbx_string filename;
		public ufbx_blob raw_filename;
		public ufbx_progress_cb progress_cb;
		public uint64 progress_interval_hint;
		public ufbx_open_file_cb open_file_cb;
		public ufbx_geometry_transform_handling geometry_transform_handling;
		public ufbx_inherit_mode_handling inherit_mode_handling;
		public ufbx_space_conversion space_conversion;
		public ufbx_pivot_handling pivot_handling;
		public bool pivot_handling_retain_empties;
		public ufbx_mirror_axis handedness_conversion_axis;
		public bool handedness_conversion_retain_winding;
		public bool reverse_winding;
		public ufbx_coordinate_axes target_axes;
		public double target_unit_meters;
		public ufbx_coordinate_axes target_camera_axes;
		public ufbx_coordinate_axes target_light_axes;
		public ufbx_string geometry_transform_helper_name;
		public ufbx_string scale_helper_name;
		public bool normalize_normals;
		public bool normalize_tangents;
		public bool use_root_transform;
		public ufbx_transform root_transform;
		public double key_clamp_threshold;
		public ufbx_unicode_error_handling unicode_error_handling;
		public bool retain_vertex_attrib_w;
		public bool retain_dom;
		public ufbx_file_format file_format;
		public uint file_format_lookahead;
		public bool no_format_from_content;
		public bool no_format_from_extension;
		public bool obj_search_mtl_by_filename;
		public bool obj_merge_objects;
		public bool obj_merge_groups;
		public bool obj_split_groups;
		public ufbx_string obj_mtl_path;
		public ufbx_blob obj_mtl_data;
		public double obj_unit_meters;
		public ufbx_coordinate_axes obj_axes;
		public uint32 _end_zero;
	}

	// -- Evaluate options

	[CRepr]
	public struct ufbx_evaluate_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public bool evaluate_skinning;
		public bool evaluate_caches;
		public uint32 evaluate_flags;
		public bool load_external_files;
		public ufbx_open_file_cb open_file_cb;
		public uint32 _end_zero;
	}

	// -- Const lists

	[CRepr]
	public struct ufbx_const_uint32_list
	{
		public uint32* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_const_real_list
	{
		public double* data;
		public uint count;
	}

	// -- Property overrides

	[CRepr]
	public struct ufbx_prop_override_desc
	{
		public uint32 element_id;
		public ufbx_string prop_name;
		public ufbx_vec4 value;
		public ufbx_string value_str;
		public int64 value_int;
	}

	[CRepr]
	public struct ufbx_const_prop_override_desc_list
	{
		public ufbx_prop_override_desc* data;
		public uint count;
	}

	[CRepr]
	public struct ufbx_const_transform_override_list
	{
		public ufbx_transform_override* data;
		public uint count;
	}

	// -- Animation options

	[CRepr]
	public struct ufbx_anim_opts
	{
		public uint32 _begin_zero;
		public ufbx_const_uint32_list layer_ids;
		public ufbx_const_real_list override_layer_weights;
		public ufbx_const_prop_override_desc_list prop_overrides;
		public ufbx_const_transform_override_list transform_overrides;
		public bool ignore_connections;
		public ufbx_allocator_opts result_allocator;
		public uint32 _end_zero;
	}

	// -- Bake step handling

	public enum ufbx_bake_step_handling : int32
	{
		UFBX_BAKE_STEP_HANDLING_DEFAULT,
		UFBX_BAKE_STEP_HANDLING_CUSTOM_DURATION,
		UFBX_BAKE_STEP_HANDLING_IDENTICAL_TIME,
		UFBX_BAKE_STEP_HANDLING_ADJACENT_DOUBLE,
		UFBX_BAKE_STEP_HANDLING_IGNORE,
	}

	// -- Bake options

	[CRepr]
	public struct ufbx_bake_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public bool trim_start_time;
		public double resample_rate;
		public double minimum_sample_rate;
		public double maximum_sample_rate;
		public bool bake_transform_props;
		public bool skip_node_transforms;
		public bool no_resample_rotation;
		public bool ignore_layer_weight_animation;
		public uint max_keyframe_segments;
		public ufbx_bake_step_handling step_handling;
		public double step_custom_duration;
		public double step_custom_epsilon;
		public uint32 evaluate_flags;
		public bool key_reduction_enabled;
		public bool key_reduction_rotation;
		public double key_reduction_threshold;
		public uint key_reduction_passes;
		public uint32 _end_zero;
	}

	// -- Tessellate/subdivide/cache options

	[CRepr]
	public struct ufbx_tessellate_curve_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public uint span_subdivision;
		public uint32 _end_zero;
	}

	[CRepr]
	public struct ufbx_tessellate_surface_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public uint span_subdivision_u;
		public uint span_subdivision_v;
		public bool skip_mesh_parts;
		public uint32 _end_zero;
	}

	[CRepr]
	public struct ufbx_subdivide_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public ufbx_subdivision_boundary boundary;
		public ufbx_subdivision_boundary uv_boundary;
		public bool ignore_normals;
		public bool interpolate_normals;
		public bool interpolate_tangents;
		public bool evaluate_source_vertices;
		public uint max_source_vertices;
		public bool evaluate_skin_weights;
		public uint max_skin_weights;
		public uint skin_deformer_index;
		public uint32 _end_zero;
	}

	[CRepr]
	public struct ufbx_geometry_cache_opts
	{
		public uint32 _begin_zero;
		public ufbx_allocator_opts temp_allocator;
		public ufbx_allocator_opts result_allocator;
		public ufbx_open_file_cb open_file_cb;
		public double frames_per_second;
		public ufbx_mirror_axis mirror_axis;
		public bool use_scale_factor;
		public double scale_factor;
		public uint32 _end_zero;
	}

	[CRepr]
	public struct ufbx_geometry_cache_data_opts
	{
		public uint32 _begin_zero;
		public ufbx_open_file_cb open_file_cb;
		public bool additive;
		public bool use_weight;
		public double weight;
		public bool ignore_transform;
		public uint32 _end_zero;
	}

	// -- Panic

	[CRepr]
	public struct ufbx_panic
	{
		public bool did_panic;
		public uint message_length;
		public char8[256] message;
	}

	// -- Transform flags

	public enum ufbx_transform_flags : uint32
	{
		UFBX_TRANSFORM_FLAG_IGNORE_SCALE_HELPER = 0x1,
		UFBX_TRANSFORM_FLAG_IGNORE_COMPONENTWISE_SCALE = 0x2,
		UFBX_TRANSFORM_FLAG_EXPLICIT_INCLUDES = 0x4,
		UFBX_TRANSFORM_FLAG_INCLUDE_TRANSLATION = 0x10,
		UFBX_TRANSFORM_FLAG_INCLUDE_ROTATION = 0x20,
		UFBX_TRANSFORM_FLAG_INCLUDE_SCALE = 0x40,
		UFBX_TRANSFORM_FLAG_NO_EXTRAPOLATION = 0x80,
	}

	// Part 4: API functions
static{
	// Extern data constants
	[CLink] public static extern ufbx_string ufbx_empty_string;
	[CLink] public static extern ufbx_blob ufbx_empty_blob;
	[CLink] public static extern ufbx_matrix ufbx_identity_matrix;
	[CLink] public static extern ufbx_transform ufbx_identity_transform;
	[CLink] public static extern ufbx_vec2 ufbx_zero_vec2;
	[CLink] public static extern ufbx_vec3 ufbx_zero_vec3;
	[CLink] public static extern ufbx_vec4 ufbx_zero_vec4;
	[CLink] public static extern ufbx_quat ufbx_identity_quat;
	[CLink] public static extern ufbx_coordinate_axes ufbx_axes_right_handed_y_up;
	[CLink] public static extern ufbx_coordinate_axes ufbx_axes_right_handed_z_up;
	[CLink] public static extern ufbx_coordinate_axes ufbx_axes_left_handed_y_up;
	[CLink] public static extern ufbx_coordinate_axes ufbx_axes_left_handed_z_up;
	[CLink] public static extern uint32 ufbx_source_version;

	// Thread safety check
	[CLink] public static extern bool ufbx_is_thread_safe();

	// Load functions
	[CLink] public static extern ufbx_scene* ufbx_load_memory(void* data, uint data_size, ufbx_load_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_scene* ufbx_load_file(char8* filename, ufbx_load_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_scene* ufbx_load_file_len(char8* filename, uint filename_len, ufbx_load_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_scene* ufbx_load_stdio(void* file, ufbx_load_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_scene* ufbx_load_stdio_prefix(void* file, void* prefix, uint prefix_size, ufbx_load_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_scene* ufbx_load_stream(ufbx_stream* stream, ufbx_load_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_scene* ufbx_load_stream_prefix(ufbx_stream* stream, void* prefix, uint prefix_size, ufbx_load_opts* opts, ufbx_error* error);

	// Scene lifetime
	[CLink] public static extern void ufbx_free_scene(ufbx_scene* scene);
	[CLink] public static extern void ufbx_retain_scene(ufbx_scene* scene);

	// Error formatting
	[CLink] public static extern uint ufbx_format_error(char8* dst, uint dst_size, ufbx_error* error);

	// Property query
	[CLink] public static extern ufbx_prop* ufbx_find_prop_len(ufbx_props* props, char8* name, uint name_len);
	[CLink] public static extern ufbx_prop* ufbx_find_prop(ufbx_props* props, char8* name);

	// Property value query
	[CLink] public static extern double ufbx_find_real_len(ufbx_props* props, char8* name, uint name_len, double def);
	[CLink] public static extern double ufbx_find_real(ufbx_props* props, char8* name, double def);
	[CLink] public static extern ufbx_vec3 ufbx_find_vec3_len(ufbx_props* props, char8* name, uint name_len, ufbx_vec3 def);
	[CLink] public static extern ufbx_vec3 ufbx_find_vec3(ufbx_props* props, char8* name, ufbx_vec3 def);
	[CLink] public static extern int64 ufbx_find_int_len(ufbx_props* props, char8* name, uint name_len, int64 def);
	[CLink] public static extern int64 ufbx_find_int(ufbx_props* props, char8* name, int64 def);
	[CLink] public static extern bool ufbx_find_bool_len(ufbx_props* props, char8* name, uint name_len, bool def);
	[CLink] public static extern bool ufbx_find_bool(ufbx_props* props, char8* name, bool def);
	[CLink] public static extern ufbx_string ufbx_find_string_len(ufbx_props* props, char8* name, uint name_len, ufbx_string def);
	[CLink] public static extern ufbx_string ufbx_find_string(ufbx_props* props, char8* name, ufbx_string def);
	[CLink] public static extern ufbx_blob ufbx_find_blob_len(ufbx_props* props, char8* name, uint name_len, ufbx_blob def);
	[CLink] public static extern ufbx_blob ufbx_find_blob(ufbx_props* props, char8* name, ufbx_blob def);

	// Property concatenated search
	[CLink] public static extern ufbx_prop* ufbx_find_prop_concat(ufbx_props* props, ufbx_string* parts, uint num_parts);

	// Property element query
	[CLink] public static extern ufbx_element* ufbx_get_prop_element(ufbx_element* element, ufbx_prop* prop, ufbx_element_type type);
	[CLink] public static extern ufbx_element* ufbx_find_prop_element_len(ufbx_element* element, char8* name, uint name_len, ufbx_element_type type);
	[CLink] public static extern ufbx_element* ufbx_find_prop_element(ufbx_element* element, char8* name, ufbx_element_type type);

	// Element search
	[CLink] public static extern ufbx_element* ufbx_find_element_len(ufbx_scene* scene, ufbx_element_type type, char8* name, uint name_len);
	[CLink] public static extern ufbx_element* ufbx_find_element(ufbx_scene* scene, ufbx_element_type type, char8* name);

	// Node search
	[CLink] public static extern ufbx_node* ufbx_find_node_len(ufbx_scene* scene, char8* name, uint name_len);
	[CLink] public static extern ufbx_node* ufbx_find_node(ufbx_scene* scene, char8* name);

	// Anim stack search
	[CLink] public static extern ufbx_anim_stack* ufbx_find_anim_stack_len(ufbx_scene* scene, char8* name, uint name_len);
	[CLink] public static extern ufbx_anim_stack* ufbx_find_anim_stack(ufbx_scene* scene, char8* name);

	// Material search
	[CLink] public static extern ufbx_material* ufbx_find_material_len(ufbx_scene* scene, char8* name, uint name_len);
	[CLink] public static extern ufbx_material* ufbx_find_material(ufbx_scene* scene, char8* name);

	// Anim prop search
	[CLink] public static extern ufbx_anim_prop* ufbx_find_anim_prop_len(ufbx_anim_layer* layer, ufbx_element* element, char8* prop, uint prop_len);
	[CLink] public static extern ufbx_anim_prop* ufbx_find_anim_prop(ufbx_anim_layer* layer, ufbx_element* element, char8* prop);
	[CLink] public static extern ufbx_anim_prop_list ufbx_find_anim_props(ufbx_anim_layer* layer, ufbx_element* element);

	// Compatible matrix for normals
	[CLink] public static extern ufbx_matrix ufbx_get_compatible_matrix_for_normals(ufbx_node* node);

	// Utility
	[CLink] public static extern int ufbx_inflate(void* dst, uint dst_size, ufbx_inflate_input* input, ufbx_inflate_retain* retain);

	// File open
	[CLink] public static extern bool ufbx_default_open_file(void* user, ufbx_stream* stream, char8* path, uint path_len, ufbx_open_file_info* info);
	[CLink] public static extern bool ufbx_open_file(ufbx_stream* stream, char8* path, uint path_len, ufbx_open_file_opts* opts, ufbx_error* error);
	[CLink] public static extern bool ufbx_open_file_ctx(ufbx_stream* stream, ufbx_open_file_context ctx, char8* path, uint path_len, ufbx_open_file_opts* opts, ufbx_error* error);

	// Memory open
	[CLink] public static extern bool ufbx_open_memory(ufbx_stream* stream, void* data, uint data_size, ufbx_open_memory_opts* opts, ufbx_error* error);
	[CLink] public static extern bool ufbx_open_memory_ctx(ufbx_stream* stream, ufbx_open_file_context ctx, void* data, uint data_size, ufbx_open_memory_opts* opts, ufbx_error* error);

	// Animation evaluation
	[CLink] public static extern double ufbx_evaluate_curve(ufbx_anim_curve* curve, double time, double default_value);
	[CLink] public static extern double ufbx_evaluate_curve_flags(ufbx_anim_curve* curve, double time, double default_value, uint32 flags);

	[CLink] public static extern double ufbx_evaluate_anim_value_real(ufbx_anim_value* anim_value, double time);
	[CLink] public static extern ufbx_vec3 ufbx_evaluate_anim_value_vec3(ufbx_anim_value* anim_value, double time);
	[CLink] public static extern double ufbx_evaluate_anim_value_real_flags(ufbx_anim_value* anim_value, double time, uint32 flags);
	[CLink] public static extern ufbx_vec3 ufbx_evaluate_anim_value_vec3_flags(ufbx_anim_value* anim_value, double time, uint32 flags);

	// Evaluate property
	[CLink] public static extern ufbx_prop ufbx_evaluate_prop_len(ufbx_anim* anim, ufbx_element* element, char8* name, uint name_len, double time);
	[CLink] public static extern ufbx_prop ufbx_evaluate_prop(ufbx_anim* anim, ufbx_element* element, char8* name, double time);
	[CLink] public static extern ufbx_prop ufbx_evaluate_prop_flags_len(ufbx_anim* anim, ufbx_element* element, char8* name, uint name_len, double time, uint32 flags);
	[CLink] public static extern ufbx_prop ufbx_evaluate_prop_flags(ufbx_anim* anim, ufbx_element* element, char8* name, double time, uint32 flags);

	// Evaluate all animated properties
	[CLink] public static extern ufbx_props ufbx_evaluate_props(ufbx_anim* anim, ufbx_element* element, double time, ufbx_prop* buffer, uint buffer_size);
	[CLink] public static extern ufbx_props ufbx_evaluate_props_flags(ufbx_anim* anim, ufbx_element* element, double time, ufbx_prop* buffer, uint buffer_size, uint32 flags);

	// Evaluate transform
	[CLink] public static extern ufbx_transform ufbx_evaluate_transform(ufbx_anim* anim, ufbx_node* node, double time);
	[CLink] public static extern ufbx_transform ufbx_evaluate_transform_flags(ufbx_anim* anim, ufbx_node* node, double time, uint32 flags);

	// Evaluate blend weight
	[CLink] public static extern double ufbx_evaluate_blend_weight(ufbx_anim* anim, ufbx_blend_channel* channel, double time);
	[CLink] public static extern double ufbx_evaluate_blend_weight_flags(ufbx_anim* anim, ufbx_blend_channel* channel, double time, uint32 flags);

	// Evaluate scene
	[CLink] public static extern ufbx_scene* ufbx_evaluate_scene(ufbx_scene* scene, ufbx_anim* anim, double time, ufbx_evaluate_opts* opts, ufbx_error* error);

	// Create/free/retain anim
	[CLink] public static extern ufbx_anim* ufbx_create_anim(ufbx_scene* scene, ufbx_anim_opts* opts, ufbx_error* error);
	[CLink] public static extern void ufbx_free_anim(ufbx_anim* anim);
	[CLink] public static extern void ufbx_retain_anim(ufbx_anim* anim);

	// Animation baking
	[CLink] public static extern ufbx_baked_anim* ufbx_bake_anim(ufbx_scene* scene, ufbx_anim* anim, ufbx_bake_opts* opts, ufbx_error* error);
	[CLink] public static extern void ufbx_retain_baked_anim(ufbx_baked_anim* bake);
	[CLink] public static extern void ufbx_free_baked_anim(ufbx_baked_anim* bake);

	// Baked anim lookup
	[CLink] public static extern ufbx_baked_node* ufbx_find_baked_node_by_typed_id(ufbx_baked_anim* bake, uint32 typed_id);
	[CLink] public static extern ufbx_baked_node* ufbx_find_baked_node(ufbx_baked_anim* bake, ufbx_node* node);
	[CLink] public static extern ufbx_baked_element* ufbx_find_baked_element_by_element_id(ufbx_baked_anim* bake, uint32 element_id);
	[CLink] public static extern ufbx_baked_element* ufbx_find_baked_element(ufbx_baked_anim* bake, ufbx_element* element);

	// Evaluate baked animation
	[CLink] public static extern ufbx_vec3 ufbx_evaluate_baked_vec3(ufbx_baked_vec3_list keyframes, double time);
	[CLink] public static extern ufbx_quat ufbx_evaluate_baked_quat(ufbx_baked_quat_list keyframes, double time);

	// Poses
	[CLink] public static extern ufbx_bone_pose* ufbx_get_bone_pose(ufbx_pose* pose, ufbx_node* node);

	// Material textures
	[CLink] public static extern ufbx_texture* ufbx_find_prop_texture_len(ufbx_material* material, char8* name, uint name_len);
	[CLink] public static extern ufbx_texture* ufbx_find_prop_texture(ufbx_material* material, char8* name);

	// Shader properties
	[CLink] public static extern ufbx_string ufbx_find_shader_prop_len(ufbx_shader* shader, char8* name, uint name_len);
	[CLink] public static extern ufbx_string ufbx_find_shader_prop(ufbx_shader* shader, char8* name);

	// Shader property bindings
	[CLink] public static extern ufbx_shader_prop_binding_list ufbx_find_shader_prop_bindings_len(ufbx_shader* shader, char8* name, uint name_len);
	[CLink] public static extern ufbx_shader_prop_binding_list ufbx_find_shader_prop_bindings(ufbx_shader* shader, char8* name);

	// Shader texture input
	[CLink] public static extern ufbx_shader_texture_input* ufbx_find_shader_texture_input_len(ufbx_shader_texture* shader, char8* name, uint name_len);
	[CLink] public static extern ufbx_shader_texture_input* ufbx_find_shader_texture_input(ufbx_shader_texture* shader, char8* name);

	// Math - coordinate axes
	[CLink] public static extern bool ufbx_coordinate_axes_valid(ufbx_coordinate_axes axes);

	// Math - vector
	[CLink] public static extern ufbx_vec3 ufbx_vec3_normalize(ufbx_vec3 v);

	// Math - quaternion
	[CLink] public static extern double ufbx_quat_dot(ufbx_quat a, ufbx_quat b);
	[CLink] public static extern ufbx_quat ufbx_quat_mul(ufbx_quat a, ufbx_quat b);
	[CLink] public static extern ufbx_quat ufbx_quat_normalize(ufbx_quat q);
	[CLink] public static extern ufbx_quat ufbx_quat_fix_antipodal(ufbx_quat q, ufbx_quat reference);
	[CLink] public static extern ufbx_quat ufbx_quat_slerp(ufbx_quat a, ufbx_quat b, double t);
	[CLink] public static extern ufbx_vec3 ufbx_quat_rotate_vec3(ufbx_quat q, ufbx_vec3 v);
	[CLink] public static extern ufbx_vec3 ufbx_quat_to_euler(ufbx_quat q, ufbx_rotation_order order);
	[CLink] public static extern ufbx_quat ufbx_euler_to_quat(ufbx_vec3 v, ufbx_rotation_order order);

	// Math - matrix
	[CLink] public static extern ufbx_matrix ufbx_matrix_mul(ufbx_matrix* a, ufbx_matrix* b);
	[CLink] public static extern double ufbx_matrix_determinant(ufbx_matrix* m);
	[CLink] public static extern ufbx_matrix ufbx_matrix_invert(ufbx_matrix* m);
	[CLink] public static extern ufbx_matrix ufbx_matrix_for_normals(ufbx_matrix* m);

	// Math - transform
	[CLink] public static extern ufbx_vec3 ufbx_transform_position(ufbx_matrix* m, ufbx_vec3 v);
	[CLink] public static extern ufbx_vec3 ufbx_transform_direction(ufbx_matrix* m, ufbx_vec3 v);
	[CLink] public static extern ufbx_matrix ufbx_transform_to_matrix(ufbx_transform* t);
	[CLink] public static extern ufbx_transform ufbx_matrix_to_transform(ufbx_matrix* m);

	// Skinning
	[CLink] public static extern ufbx_matrix ufbx_catch_get_skin_vertex_matrix(ufbx_panic* panic, ufbx_skin_deformer* skin, uint vertex, ufbx_matrix* fallback);

	// Blend shapes
	[CLink] public static extern uint32 ufbx_get_blend_shape_offset_index(ufbx_blend_shape* shape, uint vertex);
	[CLink] public static extern ufbx_vec3 ufbx_get_blend_shape_vertex_offset(ufbx_blend_shape* shape, uint vertex);
	[CLink] public static extern ufbx_vec3 ufbx_get_blend_vertex_offset(ufbx_blend_deformer* blend, uint vertex);
	[CLink] public static extern void ufbx_add_blend_shape_vertex_offsets(ufbx_blend_shape* shape, ufbx_vec3* vertices, uint num_vertices, double weight);
	[CLink] public static extern void ufbx_add_blend_vertex_offsets(ufbx_blend_deformer* blend, ufbx_vec3* vertices, uint num_vertices, double weight);

	// NURBS
	[CLink] public static extern uint ufbx_evaluate_nurbs_basis(ufbx_nurbs_basis* basis, double u, double* weights, uint num_weights, double* derivatives, uint num_derivatives);
	[CLink] public static extern ufbx_curve_point ufbx_evaluate_nurbs_curve(ufbx_nurbs_curve* curve, double u);
	[CLink] public static extern ufbx_surface_point ufbx_evaluate_nurbs_surface(ufbx_nurbs_surface* surface, double u, double v);
	[CLink] public static extern ufbx_line_curve* ufbx_tessellate_nurbs_curve(ufbx_nurbs_curve* curve, ufbx_tessellate_curve_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_mesh* ufbx_tessellate_nurbs_surface(ufbx_nurbs_surface* surface, ufbx_tessellate_surface_opts* opts, ufbx_error* error);
	[CLink] public static extern void ufbx_free_line_curve(ufbx_line_curve* curve);
	[CLink] public static extern void ufbx_retain_line_curve(ufbx_line_curve* curve);

	// Mesh topology
	[CLink] public static extern uint32 ufbx_find_face_index(ufbx_mesh* mesh, uint index);

	// Triangulation
	[CLink] public static extern uint32 ufbx_catch_triangulate_face(ufbx_panic* panic, uint32* indices, uint num_indices, ufbx_mesh* mesh, ufbx_face face);
	[CLink] public static extern uint32 ufbx_triangulate_face(uint32* indices, uint num_indices, ufbx_mesh* mesh, ufbx_face face);

	// Topology computation
	[CLink] public static extern void ufbx_catch_compute_topology(ufbx_panic* panic, ufbx_mesh* mesh, ufbx_topo_edge* topo, uint num_topo);
	[CLink] public static extern void ufbx_compute_topology(ufbx_mesh* mesh, ufbx_topo_edge* topo, uint num_topo);

	// Topology edge traversal
	[CLink] public static extern uint32 ufbx_catch_topo_next_vertex_edge(ufbx_panic* panic, ufbx_topo_edge* topo, uint num_topo, uint32 index);
	[CLink] public static extern uint32 ufbx_topo_next_vertex_edge(ufbx_topo_edge* topo, uint num_topo, uint32 index);
	[CLink] public static extern uint32 ufbx_catch_topo_prev_vertex_edge(ufbx_panic* panic, ufbx_topo_edge* topo, uint num_topo, uint32 index);
	[CLink] public static extern uint32 ufbx_topo_prev_vertex_edge(ufbx_topo_edge* topo, uint num_topo, uint32 index);

	// Weighted face normal
	[CLink] public static extern ufbx_vec3 ufbx_catch_get_weighted_face_normal(ufbx_panic* panic, ufbx_vertex_vec3* positions, ufbx_face face);
	[CLink] public static extern ufbx_vec3 ufbx_get_weighted_face_normal(ufbx_vertex_vec3* positions, ufbx_face face);

	// Normal mapping generation
	[CLink] public static extern uint ufbx_catch_generate_normal_mapping(ufbx_panic* panic, ufbx_mesh* mesh, ufbx_topo_edge* topo, uint num_topo, uint32* normal_indices, uint num_normal_indices, bool assume_smooth);
	[CLink] public static extern uint ufbx_generate_normal_mapping(ufbx_mesh* mesh, ufbx_topo_edge* topo, uint num_topo, uint32* normal_indices, uint num_normal_indices, bool assume_smooth);

	// Normal computation
	[CLink] public static extern void ufbx_catch_compute_normals(ufbx_panic* panic, ufbx_mesh* mesh, ufbx_vertex_vec3* positions, uint32* normal_indices, uint num_normal_indices, ufbx_vec3* normals, uint num_normals);
	[CLink] public static extern void ufbx_compute_normals(ufbx_mesh* mesh, ufbx_vertex_vec3* positions, uint32* normal_indices, uint num_normal_indices, ufbx_vec3* normals, uint num_normals);

	// Mesh subdivision
	[CLink] public static extern ufbx_mesh* ufbx_subdivide_mesh(ufbx_mesh* mesh, uint level, ufbx_subdivide_opts* opts, ufbx_error* error);
	[CLink] public static extern void ufbx_free_mesh(ufbx_mesh* mesh);
	[CLink] public static extern void ufbx_retain_mesh(ufbx_mesh* mesh);

	// Geometry cache
	[CLink] public static extern ufbx_geometry_cache* ufbx_load_geometry_cache(char8* filename, ufbx_geometry_cache_opts* opts, ufbx_error* error);
	[CLink] public static extern ufbx_geometry_cache* ufbx_load_geometry_cache_len(char8* filename, uint filename_len, ufbx_geometry_cache_opts* opts, ufbx_error* error);
	[CLink] public static extern void ufbx_free_geometry_cache(ufbx_geometry_cache* cache);
	[CLink] public static extern void ufbx_retain_geometry_cache(ufbx_geometry_cache* cache);
	[CLink] public static extern uint ufbx_read_geometry_cache_real(ufbx_cache_frame* frame, double* data, uint num_data, ufbx_geometry_cache_data_opts* opts);
	[CLink] public static extern uint ufbx_read_geometry_cache_vec3(ufbx_cache_frame* frame, ufbx_vec3* data, uint num_data, ufbx_geometry_cache_data_opts* opts);
	[CLink] public static extern uint ufbx_sample_geometry_cache_real(ufbx_cache_channel* channel, double time, double* data, uint num_data, ufbx_geometry_cache_data_opts* opts);
	[CLink] public static extern uint ufbx_sample_geometry_cache_vec3(ufbx_cache_channel* channel, double time, ufbx_vec3* data, uint num_data, ufbx_geometry_cache_data_opts* opts);

	// DOM
	[CLink] public static extern ufbx_dom_node* ufbx_dom_find_len(ufbx_dom_node* parent, char8* name, uint name_len);
	[CLink] public static extern ufbx_dom_node* ufbx_dom_find(ufbx_dom_node* parent, char8* name);
	[CLink] public static extern bool ufbx_dom_is_array(ufbx_dom_node* node);
	[CLink] public static extern uint ufbx_dom_array_size(ufbx_dom_node* node);
	[CLink] public static extern ufbx_int32_list ufbx_dom_as_int32_list(ufbx_dom_node* node);
	[CLink] public static extern ufbx_int64_list ufbx_dom_as_int64_list(ufbx_dom_node* node);
	[CLink] public static extern ufbx_float_list ufbx_dom_as_float_list(ufbx_dom_node* node);
	[CLink] public static extern ufbx_double_list ufbx_dom_as_double_list(ufbx_dom_node* node);
	[CLink] public static extern ufbx_real_list ufbx_dom_as_real_list(ufbx_dom_node* node);
	[CLink] public static extern ufbx_blob_list ufbx_dom_as_blob_list(ufbx_dom_node* node);

	// Index generation
	[CLink] public static extern uint ufbx_generate_indices(ufbx_vertex_stream* streams, uint num_streams, uint32* indices, uint num_indices, ufbx_allocator_opts* allocator, ufbx_error* error);

	// Thread pool
	[CLink] public static extern void ufbx_thread_pool_run_task(ufbx_thread_pool_context ctx, uint32 index);
	[CLink] public static extern void ufbx_thread_pool_set_user_ptr(ufbx_thread_pool_context ctx, void* user_ptr);
	[CLink] public static extern void* ufbx_thread_pool_get_user_ptr(ufbx_thread_pool_context ctx);

	// Catch vertex data functions
	[CLink] public static extern double ufbx_catch_get_vertex_real(ufbx_panic* panic, ufbx_vertex_real* v, uint index);
	[CLink] public static extern ufbx_vec2 ufbx_catch_get_vertex_vec2(ufbx_panic* panic, ufbx_vertex_vec2* v, uint index);
	[CLink] public static extern ufbx_vec3 ufbx_catch_get_vertex_vec3(ufbx_panic* panic, ufbx_vertex_vec3* v, uint index);
	[CLink] public static extern ufbx_vec4 ufbx_catch_get_vertex_vec4(ufbx_panic* panic, ufbx_vertex_vec4* v, uint index);
	[CLink] public static extern double ufbx_catch_get_vertex_w_vec3(ufbx_panic* panic, ufbx_vertex_vec3* v, uint index);

	// Element type cast functions
	[CLink] public static extern ufbx_unknown* ufbx_as_unknown(ufbx_element* element);
	[CLink] public static extern ufbx_node* ufbx_as_node(ufbx_element* element);
	[CLink] public static extern ufbx_mesh* ufbx_as_mesh(ufbx_element* element);
	[CLink] public static extern ufbx_light* ufbx_as_light(ufbx_element* element);
	[CLink] public static extern ufbx_camera* ufbx_as_camera(ufbx_element* element);
	[CLink] public static extern ufbx_bone* ufbx_as_bone(ufbx_element* element);
	[CLink] public static extern ufbx_empty* ufbx_as_empty(ufbx_element* element);
	[CLink] public static extern ufbx_line_curve* ufbx_as_line_curve(ufbx_element* element);
	[CLink] public static extern ufbx_nurbs_curve* ufbx_as_nurbs_curve(ufbx_element* element);
	[CLink] public static extern ufbx_nurbs_surface* ufbx_as_nurbs_surface(ufbx_element* element);
	[CLink] public static extern ufbx_nurbs_trim_surface* ufbx_as_nurbs_trim_surface(ufbx_element* element);
	[CLink] public static extern ufbx_nurbs_trim_boundary* ufbx_as_nurbs_trim_boundary(ufbx_element* element);
	[CLink] public static extern ufbx_procedural_geometry* ufbx_as_procedural_geometry(ufbx_element* element);
	[CLink] public static extern ufbx_stereo_camera* ufbx_as_stereo_camera(ufbx_element* element);
	[CLink] public static extern ufbx_camera_switcher* ufbx_as_camera_switcher(ufbx_element* element);
	[CLink] public static extern ufbx_marker* ufbx_as_marker(ufbx_element* element);
	[CLink] public static extern ufbx_lod_group* ufbx_as_lod_group(ufbx_element* element);
	[CLink] public static extern ufbx_skin_deformer* ufbx_as_skin_deformer(ufbx_element* element);
	[CLink] public static extern ufbx_skin_cluster* ufbx_as_skin_cluster(ufbx_element* element);
	[CLink] public static extern ufbx_blend_deformer* ufbx_as_blend_deformer(ufbx_element* element);
	[CLink] public static extern ufbx_blend_channel* ufbx_as_blend_channel(ufbx_element* element);
	[CLink] public static extern ufbx_blend_shape* ufbx_as_blend_shape(ufbx_element* element);
	[CLink] public static extern ufbx_cache_deformer* ufbx_as_cache_deformer(ufbx_element* element);
	[CLink] public static extern ufbx_cache_file* ufbx_as_cache_file(ufbx_element* element);
	[CLink] public static extern ufbx_material* ufbx_as_material(ufbx_element* element);
	[CLink] public static extern ufbx_texture* ufbx_as_texture(ufbx_element* element);
	[CLink] public static extern ufbx_video* ufbx_as_video(ufbx_element* element);
	[CLink] public static extern ufbx_shader* ufbx_as_shader(ufbx_element* element);
	[CLink] public static extern ufbx_shader_binding* ufbx_as_shader_binding(ufbx_element* element);
	[CLink] public static extern ufbx_anim_stack* ufbx_as_anim_stack(ufbx_element* element);
	[CLink] public static extern ufbx_anim_layer* ufbx_as_anim_layer(ufbx_element* element);
	[CLink] public static extern ufbx_anim_value* ufbx_as_anim_value(ufbx_element* element);
	[CLink] public static extern ufbx_anim_curve* ufbx_as_anim_curve(ufbx_element* element);
	[CLink] public static extern ufbx_display_layer* ufbx_as_display_layer(ufbx_element* element);
	[CLink] public static extern ufbx_selection_set* ufbx_as_selection_set(ufbx_element* element);
	[CLink] public static extern ufbx_selection_node* ufbx_as_selection_node(ufbx_element* element);
	[CLink] public static extern ufbx_character* ufbx_as_character(ufbx_element* element);
	[CLink] public static extern ufbx_constraint* ufbx_as_constraint(ufbx_element* element);
	[CLink] public static extern ufbx_audio_layer* ufbx_as_audio_layer(ufbx_element* element);
	[CLink] public static extern ufbx_audio_clip* ufbx_as_audio_clip(ufbx_element* element);
	[CLink] public static extern ufbx_pose* ufbx_as_pose(ufbx_element* element);
	[CLink] public static extern ufbx_metadata_object* ufbx_as_metadata_object(ufbx_element* element);

} // class UFBX
