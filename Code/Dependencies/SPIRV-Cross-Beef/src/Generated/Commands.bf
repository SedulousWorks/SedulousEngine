using System;

namespace SPIRV_Cross;

public class SPIRV
{
	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_get_version(uint32* major, uint32* minor, uint32* patch);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_get_commit_revision_and_timestamp();

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_vertex_attribute_init(spvc_msl_vertex_attribute* attr);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_shader_interface_var_init(spvc_msl_shader_interface_var* @var);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_shader_input_init(spvc_msl_shader_input* input);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_shader_interface_var_init_2(spvc_msl_shader_interface_var_2* @var);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_resource_binding_init(spvc_msl_resource_binding* binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_resource_binding_init_2(spvc_msl_resource_binding_2* binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_msl_get_aux_buffer_struct_version();

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_constexpr_sampler_init(spvc_msl_constexpr_sampler* sampler);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_msl_sampler_ycbcr_conversion_init(spvc_msl_sampler_ycbcr_conversion* conv);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_hlsl_resource_binding_init(spvc_hlsl_resource_binding* binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_context_create(spvc_context* context);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_context_destroy(spvc_context context);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_context_release_allocations(spvc_context context);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_context_get_last_error_string(spvc_context context);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_context_set_error_callback(spvc_context context, spvc_error_callback cb, void* userdata);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_context_parse_spirv(spvc_context context, SpvId* spirv, uint word_count, spvc_parsed_ir* parsed_ir);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_context_create_compiler(spvc_context context, spvc_backend backend, spvc_parsed_ir parsed_ir, spvc_capture_mode mode, spvc_compiler* compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_get_current_id_bound(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_create_compiler_options(spvc_compiler compiler, spvc_compiler_options* options);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_options_set_bool(spvc_compiler_options options, spvc_compiler_option option, bool value);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_options_set_uint(spvc_compiler_options options, spvc_compiler_option option, uint32 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_install_compiler_options(spvc_compiler compiler, spvc_compiler_options options);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_compile(spvc_compiler compiler, char8* source);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_add_header_line(spvc_compiler compiler, char8* line);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_require_extension(spvc_compiler compiler, char8* ext);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint spvc_compiler_get_num_required_extensions(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_required_extension(spvc_compiler compiler, uint index);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_flatten_buffer_block(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_variable_is_depth_or_compare(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_mask_stage_output_by_location(spvc_compiler compiler, uint32 location, uint32 component);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_mask_stage_output_by_builtin(spvc_compiler compiler, SpvBuiltIn builtin);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_hlsl_set_root_constants_layout(spvc_compiler compiler, spvc_hlsl_root_constants* constant_info, uint count);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_hlsl_add_vertex_attribute_remap(spvc_compiler compiler, spvc_hlsl_vertex_attribute_remap* remap, uint remaps);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_hlsl_remap_num_workgroups_builtin(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_hlsl_set_resource_binding_flags(spvc_compiler compiler, uint32 flags);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_hlsl_add_resource_binding(spvc_compiler compiler, spvc_hlsl_resource_binding* binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_hlsl_is_resource_used(spvc_compiler compiler, SpvExecutionModel model, uint32 set, uint32 binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_is_rasterization_disabled(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_needs_aux_buffer(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_needs_swizzle_buffer(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_needs_buffer_size_buffer(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_needs_output_buffer(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_needs_patch_output_buffer(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_needs_input_threadgroup_mem(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_vertex_attribute(spvc_compiler compiler, spvc_msl_vertex_attribute* attrs);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_resource_binding(spvc_compiler compiler, spvc_msl_resource_binding* binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_resource_binding_2(spvc_compiler compiler, spvc_msl_resource_binding_2* binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_shader_input(spvc_compiler compiler, spvc_msl_shader_interface_var* input);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_shader_input_2(spvc_compiler compiler, spvc_msl_shader_interface_var_2* input);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_shader_output(spvc_compiler compiler, spvc_msl_shader_interface_var* output);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_shader_output_2(spvc_compiler compiler, spvc_msl_shader_interface_var_2* output);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_discrete_descriptor_set(spvc_compiler compiler, uint32 desc_set);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_set_argument_buffer_device_address_space(spvc_compiler compiler, uint32 desc_set, bool device_address);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_is_vertex_attribute_used(spvc_compiler compiler, uint32 location);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_is_shader_input_used(spvc_compiler compiler, uint32 location);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_is_shader_output_used(spvc_compiler compiler, uint32 location);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_msl_is_resource_used(spvc_compiler compiler, SpvExecutionModel model, uint32 set, uint32 binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_remap_constexpr_sampler(spvc_compiler compiler, uint32 id, spvc_msl_constexpr_sampler* sampler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_remap_constexpr_sampler_by_binding(spvc_compiler compiler, uint32 desc_set, uint32 binding, spvc_msl_constexpr_sampler* sampler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_remap_constexpr_sampler_ycbcr(spvc_compiler compiler, uint32 id, spvc_msl_constexpr_sampler* sampler, spvc_msl_sampler_ycbcr_conversion* conv);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_remap_constexpr_sampler_by_binding_ycbcr(spvc_compiler compiler, uint32 desc_set, uint32 binding, spvc_msl_constexpr_sampler* sampler, spvc_msl_sampler_ycbcr_conversion* conv);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_set_fragment_output_components(spvc_compiler compiler, uint32 location, uint32 components);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_msl_get_automatic_resource_binding(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_msl_get_automatic_resource_binding_secondary(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_dynamic_buffer(spvc_compiler compiler, uint32 desc_set, uint32 binding, uint32 index);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_add_inline_uniform_block(spvc_compiler compiler, uint32 desc_set, uint32 binding);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_msl_set_combined_sampler_suffix(spvc_compiler compiler, char8* suffix);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_msl_get_combined_sampler_suffix(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_active_interface_variables(spvc_compiler compiler, spvc_set* set);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_set_enabled_interface_variables(spvc_compiler compiler, spvc_set set);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_create_shader_resources(spvc_compiler compiler, spvc_resources* resources);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_create_shader_resources_for_active_variables(spvc_compiler compiler, spvc_resources* resources, spvc_set active);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_resources_get_resource_list_for_type(spvc_resources resources, spvc_resource_type type, spvc_reflected_resource** resource_list, uint* resource_size);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_resources_get_builtin_resource_list_for_type(spvc_resources resources, spvc_builtin_resource_type type, spvc_reflected_builtin_resource* resource_list, uint* resource_size);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_decoration(spvc_compiler compiler, SpvId id, SpvDecoration decoration, uint32 argument);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_decoration_string(spvc_compiler compiler, SpvId id, SpvDecoration decoration, char8* argument);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_name(spvc_compiler compiler, SpvId id, char8* argument);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_member_decoration(spvc_compiler compiler, uint32 id, uint32 member_index, SpvDecoration decoration, uint32 argument);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_member_decoration_string(spvc_compiler compiler, uint32 id, uint32 member_index, SpvDecoration decoration, char8* argument);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_member_name(spvc_compiler compiler, uint32 id, uint32 member_index, char8* argument);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_unset_decoration(spvc_compiler compiler, SpvId id, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_unset_member_decoration(spvc_compiler compiler, uint32 id, uint32 member_index, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_has_decoration(spvc_compiler compiler, SpvId id, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_has_member_decoration(spvc_compiler compiler, uint32 id, uint32 member_index, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_name(spvc_compiler compiler, SpvId id);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_get_decoration(spvc_compiler compiler, SpvId id, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_decoration_string(spvc_compiler compiler, SpvId id, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_get_member_decoration(spvc_compiler compiler, uint32 id, uint32 member_index, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_member_decoration_string(spvc_compiler compiler, uint32 id, uint32 member_index, SpvDecoration decoration);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_member_name(spvc_compiler compiler, uint32 id, uint32 member_index);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_entry_points(spvc_compiler compiler, spvc_entry_point* entry_points, uint* num_entry_points);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_set_entry_point(spvc_compiler compiler, char8* name, SpvExecutionModel model);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_rename_entry_point(spvc_compiler compiler, char8* old_name, char8* new_name, SpvExecutionModel model);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_cleansed_entry_point_name(spvc_compiler compiler, char8* name, SpvExecutionModel model);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_execution_mode(spvc_compiler compiler, SpvExecutionMode mode);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_unset_execution_mode(spvc_compiler compiler, SpvExecutionMode mode);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_set_execution_mode_with_arguments(spvc_compiler compiler, SpvExecutionMode mode, uint32 arg0, uint32 arg1, uint32 arg2);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_execution_modes(spvc_compiler compiler, SpvExecutionMode* modes, uint* num_modes);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_get_execution_mode_argument(spvc_compiler compiler, SpvExecutionMode mode);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_get_execution_mode_argument_by_index(spvc_compiler compiler, SpvExecutionMode mode, uint32 index);

	[CallingConvention(.Stdcall), CLink]
	public static extern SpvExecutionModel spvc_compiler_get_execution_model(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_compiler_update_active_builtins(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_has_active_builtin(spvc_compiler compiler, SpvBuiltIn builtin, SpvStorageClass storage);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_type spvc_compiler_get_type_handle(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_base_type_id(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_basetype spvc_type_get_basetype(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_bit_width(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_vector_size(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_columns(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_num_array_dimensions(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_type_array_dimension_is_literal(spvc_type type, uint32 dimension);

	[CallingConvention(.Stdcall), CLink]
	public static extern SpvId spvc_type_get_array_dimension(spvc_type type, uint32 dimension);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_num_member_types(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_member_type(spvc_type type, uint32 index);

	[CallingConvention(.Stdcall), CLink]
	public static extern SpvStorageClass spvc_type_get_storage_class(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_type_get_image_sampled_type(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern SpvDim spvc_type_get_image_dimension(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_type_get_image_is_depth(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_type_get_image_arrayed(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_type_get_image_multisampled(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_type_get_image_is_storage(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern SpvImageFormat spvc_type_get_image_storage_format(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern SpvAccessQualifier spvc_type_get_image_access_qualifier(spvc_type type);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_declared_struct_size(spvc_compiler compiler, spvc_type struct_type, uint* size);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_declared_struct_size_runtime_array(spvc_compiler compiler, spvc_type struct_type, uint array_size, uint* size);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_declared_struct_member_size(spvc_compiler compiler, spvc_type type, uint32 index, uint* size);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_type_struct_member_offset(spvc_compiler compiler, spvc_type type, uint32 index, uint32* offset);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_type_struct_member_array_stride(spvc_compiler compiler, spvc_type type, uint32 index, uint32* stride);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_type_struct_member_matrix_stride(spvc_compiler compiler, spvc_type type, uint32 index, uint32* stride);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_build_dummy_sampler_for_combined_images(spvc_compiler compiler, uint32* id);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_build_combined_image_samplers(spvc_compiler compiler);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_combined_image_samplers(spvc_compiler compiler, spvc_combined_image_sampler* samplers, uint* num_samplers);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_specialization_constants(spvc_compiler compiler, spvc_specialization_constant* constants, uint* num_constants);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_constant spvc_compiler_get_constant_handle(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_compiler_get_work_group_size_specialization_constants(spvc_compiler compiler, spvc_specialization_constant* x, spvc_specialization_constant* y, spvc_specialization_constant* z);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_active_buffer_ranges(spvc_compiler compiler, uint32 id, spvc_buffer_range* ranges, uint* num_ranges);

	[CallingConvention(.Stdcall), CLink]
	public static extern float spvc_constant_get_scalar_fp16(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern float spvc_constant_get_scalar_fp32(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern double spvc_constant_get_scalar_fp64(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_constant_get_scalar_u32(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern int32 spvc_constant_get_scalar_i32(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_constant_get_scalar_u16(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern int32 spvc_constant_get_scalar_i16(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_constant_get_scalar_u8(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern int32 spvc_constant_get_scalar_i8(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_get_subconstants(spvc_constant constant, uint32* constituents, uint* count);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint64 spvc_constant_get_scalar_u64(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern int64 spvc_constant_get_scalar_i64(spvc_constant constant, uint32 column, uint32 row);

	[CallingConvention(.Stdcall), CLink]
	public static extern uint32 spvc_constant_get_type(spvc_constant constant);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_fp16(spvc_constant constant, uint32 column, uint32 row, uint16 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_fp32(spvc_constant constant, uint32 column, uint32 row, float value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_fp64(spvc_constant constant, uint32 column, uint32 row, double value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_u32(spvc_constant constant, uint32 column, uint32 row, uint32 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_i32(spvc_constant constant, uint32 column, uint32 row, int32 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_u64(spvc_constant constant, uint32 column, uint32 row, uint64 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_i64(spvc_constant constant, uint32 column, uint32 row, int64 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_u16(spvc_constant constant, uint32 column, uint32 row, uint16 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_i16(spvc_constant constant, uint32 column, uint32 row, int16 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_u8(spvc_constant constant, uint32 column, uint32 row, uint8 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern void spvc_constant_set_scalar_i8(spvc_constant constant, uint32 column, uint32 row, char8 value);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_get_binary_offset_for_decoration(spvc_compiler compiler, uint32 id, SpvDecoration decoration, uint32* word_offset);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_buffer_is_hlsl_counter_buffer(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern bool spvc_compiler_buffer_get_hlsl_counter_buffer(spvc_compiler compiler, uint32 id, uint32* counter_id);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_declared_capabilities(spvc_compiler compiler, SpvCapability* capabilities, uint* num_capabilities);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_declared_extensions(spvc_compiler compiler, char8* extensions, uint* num_extensions);

	[CallingConvention(.Stdcall), CLink]
	public static extern char8* spvc_compiler_get_remapped_declared_block_name(spvc_compiler compiler, uint32 id);

	[CallingConvention(.Stdcall), CLink]
	public static extern spvc_result spvc_compiler_get_buffer_block_decorations(spvc_compiler compiler, uint32 id, SpvDecoration** decorations, uint* num_decorations);

}
