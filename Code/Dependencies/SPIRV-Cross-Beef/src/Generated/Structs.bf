using System;

namespace SPIRV_Cross;

[CRepr]
public struct spvc_reflected_resource
{
	public uint32 id;
	public uint32 base_type_id;
	public uint32 type_id;
	public char8* name;
}

[CRepr]
public struct spvc_reflected_builtin_resource
{
	public SpvBuiltIn builtin;
	public uint32 value_type_id;
	public spvc_reflected_resource resource;
}

[CRepr]
public struct spvc_entry_point
{
	public SpvExecutionModel execution_model;
	public char8* name;
}

[CRepr]
public struct spvc_combined_image_sampler
{
	public uint32 combined_id;
	public uint32 image_id;
	public uint32 sampler_id;
}

[CRepr]
public struct spvc_specialization_constant
{
	public uint32 id;
	public uint32 constant_id;
}

[CRepr]
public struct spvc_buffer_range
{
	public uint32 index;
	public uint offset;
	public uint range;
}

[CRepr]
public struct spvc_hlsl_root_constants
{
	public uint32 start;
	public uint32 end;
	public uint32 binding;
	public uint32 space;
}

[CRepr]
public struct spvc_hlsl_vertex_attribute_remap
{
	public uint32 location;
	public char8* semantic;
}

[CRepr]
public struct spvc_msl_vertex_attribute
{
	public uint32 location;
	public uint32 msl_buffer;
	public uint32 msl_offset;
	public uint32 msl_stride;
	public bool per_instance;
	public spvc_msl_vertex_format format;
	public SpvBuiltIn builtin;
}

[CRepr]
public struct spvc_msl_shader_interface_var
{
	public uint32 location;
	public spvc_msl_vertex_format format;
	public SpvBuiltIn builtin;
	public uint32 vecsize;
}

[CRepr]
public struct spvc_msl_shader_interface_var_2
{
	public uint32 location;
	public spvc_msl_shader_variable_format format;
	public SpvBuiltIn builtin;
	public uint32 vecsize;
	public spvc_msl_shader_variable_rate rate;
}

[CRepr]
public struct spvc_msl_resource_binding
{
	public SpvExecutionModel stage;
	public uint32 desc_set;
	public uint32 binding;
	public uint32 msl_buffer;
	public uint32 msl_texture;
	public uint32 msl_sampler;
}

[CRepr]
public struct spvc_msl_resource_binding_2
{
	public SpvExecutionModel stage;
	public uint32 desc_set;
	public uint32 binding;
	public uint32 count;
	public uint32 msl_buffer;
	public uint32 msl_texture;
	public uint32 msl_sampler;
}

[CRepr]
public struct spvc_msl_constexpr_sampler
{
	public spvc_msl_sampler_coord coord;
	public spvc_msl_sampler_filter min_filter;
	public spvc_msl_sampler_filter mag_filter;
	public spvc_msl_sampler_mip_filter mip_filter;
	public spvc_msl_sampler_address s_address;
	public spvc_msl_sampler_address t_address;
	public spvc_msl_sampler_address r_address;
	public spvc_msl_sampler_compare_func compare_func;
	public spvc_msl_sampler_border_color border_color;
	public float lod_clamp_min;
	public float lod_clamp_max;
	public int32 max_anisotropy;
	public bool compare_enable;
	public bool lod_clamp_enable;
	public bool anisotropy_enable;
}

[CRepr]
public struct spvc_msl_sampler_ycbcr_conversion
{
	public uint32 planes;
	public spvc_msl_format_resolution resolution;
	public spvc_msl_sampler_filter chroma_filter;
	public spvc_msl_chroma_location x_chroma_offset;
	public spvc_msl_chroma_location y_chroma_offset;
	public spvc_msl_component_swizzle swizzle_0;
	public spvc_msl_component_swizzle swizzle_1;
	public spvc_msl_component_swizzle swizzle_2;
	public spvc_msl_component_swizzle swizzle_3;
	public spvc_msl_sampler_ycbcr_model_conversion ycbcr_model;
	public spvc_msl_sampler_ycbcr_range ycbcr_range;
	public uint32 bpc;
}

[CRepr]
public struct spvc_hlsl_resource_binding_mapping
{
	public uint32 register_space;
	public uint32 register_binding;
}

[CRepr]
public struct spvc_hlsl_resource_binding
{
	public SpvExecutionModel stage;
	public uint32 desc_set;
	public uint32 binding;
	public spvc_hlsl_resource_binding_mapping cbv;
	public spvc_hlsl_resource_binding_mapping uav;
	public spvc_hlsl_resource_binding_mapping srv;
	public spvc_hlsl_resource_binding_mapping sampler;
}

