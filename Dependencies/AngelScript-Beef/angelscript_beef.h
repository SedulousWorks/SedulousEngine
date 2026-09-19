/* A C interface over AngelScript for Beef.
 *
 * AngelScript's own interface is C++ (virtual classes), which Beef cannot call. This is the
 * flat C surface the Beef binding declares, kept to what a host that binds a generated
 * surface needs: registration with the GENERIC calling convention only (the portable path,
 * and the only one on wasm), modules, contexts, and the generic call's arguments and return.
 *
 * Every application function AngelScript calls goes through ONE trampoline (asc_generic_fn)
 * that receives the auxiliary pointer the registration was given; the host keys its own
 * dispatch off that. The `string` type is the SDK's std::string add-on, with accessors so the
 * host reads and writes it without knowing std::string; `array<T>` is the SDK's add-on too.
 *
 * The vendored angelscript/ and add_on/ trees are left exactly as the SDK ships them.
 */

#ifndef ANGELSCRIPT_BEEF_H_
#define ANGELSCRIPT_BEEF_H_

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct asc_engine   asc_engine;
typedef struct asc_module   asc_module;
typedef struct asc_context  asc_context;
typedef struct asc_function asc_function;
typedef struct asc_typeinfo asc_typeinfo;
typedef struct asc_generic  asc_generic;
typedef struct asc_object   asc_object;

/* A compiler or runtime message: type is asEMsgType. */
typedef void (*asc_message_fn)(const char* section, int row, int col, int type, const char* message, void* user);
/* The one target of every generic call: aux is what the registration passed. */
typedef void (*asc_generic_fn)(asc_generic* gen, void* aux, void* user);

/* ---- engine ---- */
asc_engine* asc_engine_create(void);
void        asc_engine_release(asc_engine* engine);
void        asc_engine_set_message_callback(asc_engine* engine, asc_message_fn fn, void* user);
void        asc_engine_set_generic_callback(asc_engine* engine, asc_generic_fn fn, void* user);
int         asc_engine_set_property(asc_engine* engine, int property, size_t value);
/* The SDK's std::string `string` and `array<T>` types. Register the string first: the array
 * brings the string utilities (split, join) with it when the string exists. */
void        asc_engine_register_std_string(asc_engine* engine);
void        asc_engine_register_script_array(asc_engine* engine, int defaultArray);
int         asc_engine_set_default_namespace(asc_engine* engine, const char* ns);

/* ---- registration (generic calling convention) ---- */
int asc_engine_register_object_type(asc_engine* engine, const char* name, int byteSize, uint64_t flags);
int asc_engine_register_object_method(asc_engine* engine, const char* obj, const char* decl, void* aux);
int asc_engine_register_object_behaviour(asc_engine* engine, const char* obj, int behaviour, const char* decl, void* aux);
int asc_engine_register_object_property(asc_engine* engine, const char* obj, const char* decl, int byteOffset);
int asc_engine_register_global_function(asc_engine* engine, const char* decl, void* aux);
int asc_engine_register_global_property(asc_engine* engine, const char* decl, void* pointer);
int asc_engine_register_enum(asc_engine* engine, const char* name);
int asc_engine_register_enum_value(asc_engine* engine, const char* type, const char* name, int value);
int asc_engine_register_funcdef(asc_engine* engine, const char* decl);
int asc_engine_register_interface(asc_engine* engine, const char* name);
int asc_engine_register_interface_method(asc_engine* engine, const char* intf, const char* decl);

/* ---- types ---- */
int           asc_engine_get_type_id_by_decl(asc_engine* engine, const char* decl);
asc_typeinfo* asc_engine_get_type_info_by_name(asc_engine* engine, const char* name);
asc_typeinfo* asc_engine_get_type_info_by_decl(asc_engine* engine, const char* decl);
asc_typeinfo* asc_engine_get_type_info_by_id(asc_engine* engine, int typeId);
const char*   asc_engine_get_type_declaration(asc_engine* engine, int typeId, int includeNamespace);
const char*   asc_typeinfo_get_name(asc_typeinfo* type);
const char*   asc_typeinfo_get_namespace(asc_typeinfo* type);
int           asc_typeinfo_get_type_id(asc_typeinfo* type);
uint64_t      asc_typeinfo_get_flags(asc_typeinfo* type);
int           asc_typeinfo_get_size(asc_typeinfo* type);
asc_typeinfo* asc_typeinfo_get_base_type(asc_typeinfo* type);
int           asc_typeinfo_implements(asc_typeinfo* type, asc_typeinfo* intf);
unsigned      asc_typeinfo_get_method_count(asc_typeinfo* type);
asc_function* asc_typeinfo_get_method_by_index(asc_typeinfo* type, unsigned index);
asc_function* asc_typeinfo_get_method_by_decl(asc_typeinfo* type, const char* decl);
asc_function* asc_typeinfo_get_method_by_name(asc_typeinfo* type, const char* name);
unsigned      asc_typeinfo_get_factory_count(asc_typeinfo* type);
asc_function* asc_typeinfo_get_factory_by_index(asc_typeinfo* type, unsigned index);
asc_function* asc_typeinfo_get_factory_by_decl(asc_typeinfo* type, const char* decl);
unsigned      asc_typeinfo_get_property_count(asc_typeinfo* type);
int           asc_typeinfo_get_property(asc_typeinfo* type, unsigned index, const char** name, int* typeId, int* offset);
/* isPrivate / isProtected: 1 when so, for a script class's members. */
int           asc_typeinfo_get_property_access(asc_typeinfo* type, unsigned index, int* isPrivate, int* isProtected);

/* ---- functions ---- */
const char*   asc_function_get_name(asc_function* fn);
const char*   asc_function_get_declaration(asc_function* fn, int includeObjectName, int includeNamespace, int includeParamNames);
unsigned      asc_function_get_param_count(asc_function* fn);
int           asc_function_get_param(asc_function* fn, unsigned index, int* typeId, uint32_t* flags, const char** name);
int           asc_function_get_return_type_id(asc_function* fn, uint32_t* flags);
asc_typeinfo* asc_function_get_object_type(asc_function* fn);

/* ---- modules ---- */
asc_module*   asc_engine_get_module(asc_engine* engine, const char* name, int flags);
void          asc_module_discard(asc_module* module);
const char*   asc_module_get_name(asc_module* module);
int           asc_module_add_script_section(asc_module* module, const char* name, const char* code, size_t length);
int           asc_module_build(asc_module* module);
unsigned      asc_module_get_function_count(asc_module* module);
asc_function* asc_module_get_function_by_index(asc_module* module, unsigned index);
asc_function* asc_module_get_function_by_decl(asc_module* module, const char* decl);
asc_function* asc_module_get_function_by_name(asc_module* module, const char* name);
unsigned      asc_module_get_object_type_count(asc_module* module);
asc_typeinfo* asc_module_get_object_type_by_index(asc_module* module, unsigned index);
asc_typeinfo* asc_module_get_type_info_by_name(asc_module* module, const char* name);
asc_typeinfo* asc_module_get_type_info_by_decl(asc_module* module, const char* decl);
unsigned      asc_module_get_global_var_count(asc_module* module);
void*         asc_module_get_address_of_global_var(asc_module* module, unsigned index);

/* ---- contexts ---- */
asc_context*  asc_engine_create_context(asc_engine* engine);
void          asc_context_release(asc_context* ctx);
int           asc_context_prepare(asc_context* ctx, asc_function* fn);
int           asc_context_unprepare(asc_context* ctx);
int           asc_context_set_object(asc_context* ctx, void* obj);
int           asc_context_set_arg_byte(asc_context* ctx, unsigned arg, uint8_t value);
int           asc_context_set_arg_word(asc_context* ctx, unsigned arg, uint16_t value);
int           asc_context_set_arg_dword(asc_context* ctx, unsigned arg, uint32_t value);
int           asc_context_set_arg_qword(asc_context* ctx, unsigned arg, uint64_t value);
int           asc_context_set_arg_float(asc_context* ctx, unsigned arg, float value);
int           asc_context_set_arg_double(asc_context* ctx, unsigned arg, double value);
int           asc_context_set_arg_address(asc_context* ctx, unsigned arg, void* address);
int           asc_context_set_arg_object(asc_context* ctx, unsigned arg, void* obj);
int           asc_context_execute(asc_context* ctx);
int           asc_context_abort(asc_context* ctx);
int           asc_context_get_state(asc_context* ctx);
uint8_t       asc_context_get_return_byte(asc_context* ctx);
uint16_t      asc_context_get_return_word(asc_context* ctx);
uint32_t      asc_context_get_return_dword(asc_context* ctx);
uint64_t      asc_context_get_return_qword(asc_context* ctx);
float         asc_context_get_return_float(asc_context* ctx);
double        asc_context_get_return_double(asc_context* ctx);
void*         asc_context_get_return_address(asc_context* ctx);
void*         asc_context_get_return_object(asc_context* ctx);
void*         asc_context_get_address_of_return_value(asc_context* ctx);
const char*   asc_context_get_exception_string(asc_context* ctx);
asc_function* asc_context_get_exception_function(asc_context* ctx);
int           asc_context_get_exception_line_number(asc_context* ctx, int* column, const char** section);
/* Raises an exception in the context of the generic call in progress. */
int           asc_set_active_exception(const char* message);
/* The context running the generic call in progress, null outside one. */
asc_context*  asc_get_active_context(void);
/* Asks the running context to suspend at the next opportunity; Execute then returns
 * asEXECUTION_SUSPENDED and a later Execute resumes it. */
int           asc_context_suspend(asc_context* ctx);

/* ---- debugging: a line callback, and the call stack and variables of a suspended context ---- */
typedef void (*asc_line_fn)(asc_context* ctx, void* user);
/* Called before every line the context executes; the callback may suspend the context. */
int           asc_context_set_line_callback(asc_context* ctx, asc_line_fn fn, void* user);
void          asc_context_clear_line_callback(asc_context* ctx);
unsigned      asc_context_get_callstack_size(asc_context* ctx);
/* Level 0 is the innermost frame. Section is the script section name the line is in. */
asc_function* asc_context_get_function(asc_context* ctx, unsigned level);
int           asc_context_get_line_number(asc_context* ctx, unsigned level, int* column, const char** section);
int           asc_context_get_var_count(asc_context* ctx, unsigned level);
int           asc_context_get_var(asc_context* ctx, unsigned index, unsigned level, const char** name, int* typeId);
const char*   asc_context_get_var_declaration(asc_context* ctx, unsigned index, unsigned level);
/* Null for a variable not yet initialised. */
void*         asc_context_get_address_of_var(asc_context* ctx, unsigned index, unsigned level);
int           asc_context_is_var_in_scope(asc_context* ctx, unsigned index, unsigned level);
int           asc_context_get_this_type_id(asc_context* ctx, unsigned level);
void*         asc_context_get_this_pointer(asc_context* ctx, unsigned level);
void*         asc_context_get_user_data(asc_context* ctx);
void          asc_context_set_user_data(asc_context* ctx, void* data);

/* ---- function handles (funcdefs, delegates) ---- */
void          asc_function_add_ref(asc_function* fn);
void          asc_function_release(asc_function* fn);
/* For a delegate: the object it is bound to and the method; null for a plain function. */
void*         asc_function_get_delegate_object(asc_function* fn);
asc_function* asc_function_get_delegate_function(asc_function* fn);

/* ---- the generic call ---- */
asc_engine*   asc_generic_get_engine(asc_generic* gen);
void*         asc_generic_get_aux(asc_generic* gen);
asc_function* asc_generic_get_function(asc_generic* gen);
void*         asc_generic_get_object(asc_generic* gen);
int           asc_generic_get_object_type_id(asc_generic* gen);
int           asc_generic_get_arg_count(asc_generic* gen);
int           asc_generic_get_arg_type_id(asc_generic* gen, unsigned arg, uint32_t* flags);
uint8_t       asc_generic_get_arg_byte(asc_generic* gen, unsigned arg);
uint16_t      asc_generic_get_arg_word(asc_generic* gen, unsigned arg);
uint32_t      asc_generic_get_arg_dword(asc_generic* gen, unsigned arg);
uint64_t      asc_generic_get_arg_qword(asc_generic* gen, unsigned arg);
float         asc_generic_get_arg_float(asc_generic* gen, unsigned arg);
double        asc_generic_get_arg_double(asc_generic* gen, unsigned arg);
void*         asc_generic_get_arg_address(asc_generic* gen, unsigned arg);
void*         asc_generic_get_arg_object(asc_generic* gen, unsigned arg);
void*         asc_generic_get_address_of_arg(asc_generic* gen, unsigned arg);
int           asc_generic_get_return_type_id(asc_generic* gen, uint32_t* flags);
int           asc_generic_set_return_byte(asc_generic* gen, uint8_t value);
int           asc_generic_set_return_word(asc_generic* gen, uint16_t value);
int           asc_generic_set_return_dword(asc_generic* gen, uint32_t value);
int           asc_generic_set_return_qword(asc_generic* gen, uint64_t value);
int           asc_generic_set_return_float(asc_generic* gen, float value);
int           asc_generic_set_return_double(asc_generic* gen, double value);
int           asc_generic_set_return_address(asc_generic* gen, void* address);
int           asc_generic_set_return_object(asc_generic* gen, void* obj);
void*         asc_generic_get_address_of_return_location(asc_generic* gen);

/* ---- script objects (instances of script classes) ---- */
asc_object*   asc_engine_create_script_object(asc_engine* engine, asc_typeinfo* type);
void          asc_object_add_ref(asc_object* obj);
void          asc_object_release(asc_object* obj);
asc_typeinfo* asc_object_get_type(asc_object* obj);
unsigned      asc_object_get_property_count(asc_object* obj);
int           asc_object_get_property_type_id(asc_object* obj, unsigned index);
const char*   asc_object_get_property_name(asc_object* obj, unsigned index);
void*         asc_object_get_address_of_property(asc_object* obj, unsigned index);

/* ---- the std::string `string` ---- */
const char*   asc_string_data(const void* str, size_t* length);
void          asc_string_assign(void* str, const char* data, size_t length);
/* Placement-constructs a string at `memory` (a return location, say); asc_string_destruct undoes it. */
void          asc_string_construct(void* memory, const char* data, size_t length);
void          asc_string_destruct(void* str);
size_t        asc_string_size(void);

/* ---- the `array<T>` add-on ---- */
unsigned      asc_array_get_size(const void* arr);
void*         asc_array_at(void* arr, unsigned index);
void          asc_array_resize(void* arr, unsigned size);
int           asc_array_get_element_type_id(const void* arr);
/* Creates an array of the element type named by the declaration, e.g. "array<float>". Released with asc_array_release. */
void*         asc_array_create(asc_engine* engine, const char* decl, unsigned length);
void          asc_array_add_ref(void* arr);
void          asc_array_release(void* arr);

#ifdef __cplusplus
}
#endif

#endif
