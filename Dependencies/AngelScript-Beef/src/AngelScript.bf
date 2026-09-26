using System;

namespace AngelScript;

/// The C interface over AngelScript (angelscript_beef.h), declared for Beef.
///
/// Handles are opaque pointers. Every application function AngelScript calls arrives
/// through the ONE generic callback set with asc_engine_set_generic_callback, with the
/// auxiliary pointer the registration passed. Return codes are asERetCodes: 0 or positive
/// is success, negative is the error.
static class AS
{
	public struct Engine {}
	public struct Module {}
	public struct Context {}
	public struct Function {}
	public struct TypeInfo {}
	public struct Generic {}
	public struct ScriptObject {}

	public typealias MessageFn = function void(char8* section, int32 row, int32 col, int32 type, char8* message, void* user);
	public typealias GenericFn = function void(Generic* gen, void* aux, void* user);

	// ---- engine ----
	[CLink] public static extern Engine* asc_engine_create();
	/// AngelScript's own C API: frees the CALLING thread's local data, which the library keeps
	/// per thread and otherwise frees only for the thread that releases the last engine. A
	/// worker that used an engine calls it before exiting. Refused (a negative result) while a
	/// context is active on the thread.
	[CLink] public static extern int32 asThreadCleanup();
	/// AngelScript's own C API: takes a reference on the process wide thread manager, creating it
	/// on first use. AngelScript requires this before any thread but the first creates an
	/// engine; a reference that is never released keeps the manager alive for the process, so
	/// engines created and released on workers never race its creation or deletion. Pass null.
	[CLink] public static extern int32 asPrepareMultithread(void* externalManager);
	[CLink] public static extern void asc_engine_release(Engine* engine);
	[CLink] public static extern void asc_engine_set_message_callback(Engine* engine, MessageFn fn, void* user);
	[CLink] public static extern void asc_engine_set_generic_callback(Engine* engine, GenericFn fn, void* user);
	[CLink] public static extern int32 asc_engine_set_property(Engine* engine, int32 property, uint value);
	[CLink] public static extern void asc_engine_register_std_string(Engine* engine);
	[CLink] public static extern void asc_engine_register_script_array(Engine* engine, int32 defaultArray);
	[CLink] public static extern int32 asc_engine_set_default_namespace(Engine* engine, char8* ns);

	// ---- registration ----
	[CLink] public static extern int32 asc_engine_register_object_type(Engine* engine, char8* name, int32 byteSize, uint64 flags);
	[CLink] public static extern int32 asc_engine_register_object_method(Engine* engine, char8* obj, char8* decl, void* aux);
	[CLink] public static extern int32 asc_engine_register_object_behaviour(Engine* engine, char8* obj, int32 behaviour, char8* decl, void* aux);
	[CLink] public static extern int32 asc_engine_register_object_property(Engine* engine, char8* obj, char8* decl, int32 byteOffset);
	[CLink] public static extern int32 asc_engine_register_global_function(Engine* engine, char8* decl, void* aux);
	[CLink] public static extern int32 asc_engine_register_global_property(Engine* engine, char8* decl, void* pointer);
	[CLink] public static extern int32 asc_engine_register_enum(Engine* engine, char8* name);
	[CLink] public static extern int32 asc_engine_register_enum_value(Engine* engine, char8* type, char8* name, int32 value);
	[CLink] public static extern int32 asc_engine_register_funcdef(Engine* engine, char8* decl);
	[CLink] public static extern int32 asc_engine_register_interface(Engine* engine, char8* name);
	[CLink] public static extern int32 asc_engine_register_interface_method(Engine* engine, char8* intf, char8* decl);

	// ---- types ----
	[CLink] public static extern int32 asc_engine_get_type_id_by_decl(Engine* engine, char8* decl);
	[CLink] public static extern TypeInfo* asc_engine_get_type_info_by_name(Engine* engine, char8* name);
	[CLink] public static extern TypeInfo* asc_engine_get_type_info_by_decl(Engine* engine, char8* decl);
	[CLink] public static extern TypeInfo* asc_engine_get_type_info_by_id(Engine* engine, int32 typeId);
	[CLink] public static extern char8* asc_engine_get_type_declaration(Engine* engine, int32 typeId, int32 includeNamespace);
	[CLink] public static extern char8* asc_typeinfo_get_name(TypeInfo* type);
	[CLink] public static extern char8* asc_typeinfo_get_namespace(TypeInfo* type);
	[CLink] public static extern int32 asc_typeinfo_get_type_id(TypeInfo* type);
	[CLink] public static extern uint64 asc_typeinfo_get_flags(TypeInfo* type);
	[CLink] public static extern int32 asc_typeinfo_get_size(TypeInfo* type);
	[CLink] public static extern TypeInfo* asc_typeinfo_get_base_type(TypeInfo* type);
	[CLink] public static extern int32 asc_typeinfo_implements(TypeInfo* type, TypeInfo* intf);
	[CLink] public static extern uint32 asc_typeinfo_get_method_count(TypeInfo* type);
	[CLink] public static extern Function* asc_typeinfo_get_method_by_index(TypeInfo* type, uint32 index);
	[CLink] public static extern Function* asc_typeinfo_get_method_by_decl(TypeInfo* type, char8* decl);
	[CLink] public static extern Function* asc_typeinfo_get_method_by_name(TypeInfo* type, char8* name);
	[CLink] public static extern uint32 asc_typeinfo_get_factory_count(TypeInfo* type);
	[CLink] public static extern Function* asc_typeinfo_get_factory_by_index(TypeInfo* type, uint32 index);
	[CLink] public static extern Function* asc_typeinfo_get_factory_by_decl(TypeInfo* type, char8* decl);
	[CLink] public static extern uint32 asc_typeinfo_get_property_count(TypeInfo* type);
	[CLink] public static extern int32 asc_typeinfo_get_property(TypeInfo* type, uint32 index, char8** name, int32* typeId, int32* offset);
	[CLink] public static extern int32 asc_typeinfo_get_property_access(TypeInfo* type, uint32 index, int32* isPrivate, int32* isProtected);

	// ---- functions ----
	[CLink] public static extern char8* asc_function_get_name(Function* fn);
	[CLink] public static extern char8* asc_function_get_declaration(Function* fn, int32 includeObjectName, int32 includeNamespace, int32 includeParamNames);
	[CLink] public static extern uint32 asc_function_get_param_count(Function* fn);
	[CLink] public static extern int32 asc_function_get_param(Function* fn, uint32 index, int32* typeId, uint32* flags, char8** name);
	[CLink] public static extern int32 asc_function_get_return_type_id(Function* fn, uint32* flags);
	[CLink] public static extern TypeInfo* asc_function_get_object_type(Function* fn);

	// ---- modules ----
	[CLink] public static extern Module* asc_engine_get_module(Engine* engine, char8* name, int32 flags);
	[CLink] public static extern void asc_module_discard(Module* module);
	[CLink] public static extern char8* asc_module_get_name(Module* module);
	[CLink] public static extern int32 asc_module_add_script_section(Module* module, char8* name, char8* code, uint length);
	[CLink] public static extern int32 asc_module_build(Module* module);
	[CLink] public static extern uint32 asc_module_get_function_count(Module* module);
	[CLink] public static extern Function* asc_module_get_function_by_index(Module* module, uint32 index);
	[CLink] public static extern Function* asc_module_get_function_by_decl(Module* module, char8* decl);
	[CLink] public static extern Function* asc_module_get_function_by_name(Module* module, char8* name);
	[CLink] public static extern uint32 asc_module_get_object_type_count(Module* module);
	[CLink] public static extern TypeInfo* asc_module_get_object_type_by_index(Module* module, uint32 index);
	[CLink] public static extern TypeInfo* asc_module_get_type_info_by_name(Module* module, char8* name);
	[CLink] public static extern TypeInfo* asc_module_get_type_info_by_decl(Module* module, char8* decl);
	[CLink] public static extern uint32 asc_module_get_global_var_count(Module* module);
	[CLink] public static extern void* asc_module_get_address_of_global_var(Module* module, uint32 index);

	// ---- contexts ----
	[CLink] public static extern Context* asc_engine_create_context(Engine* engine);
	[CLink] public static extern void asc_context_release(Context* ctx);
	[CLink] public static extern int32 asc_context_prepare(Context* ctx, Function* fn);
	[CLink] public static extern int32 asc_context_unprepare(Context* ctx);
	[CLink] public static extern int32 asc_context_set_object(Context* ctx, void* obj);
	[CLink] public static extern int32 asc_context_set_arg_byte(Context* ctx, uint32 arg, uint8 value);
	[CLink] public static extern int32 asc_context_set_arg_word(Context* ctx, uint32 arg, uint16 value);
	[CLink] public static extern int32 asc_context_set_arg_dword(Context* ctx, uint32 arg, uint32 value);
	[CLink] public static extern int32 asc_context_set_arg_qword(Context* ctx, uint32 arg, uint64 value);
	[CLink] public static extern int32 asc_context_set_arg_float(Context* ctx, uint32 arg, float value);
	[CLink] public static extern int32 asc_context_set_arg_double(Context* ctx, uint32 arg, double value);
	[CLink] public static extern int32 asc_context_set_arg_address(Context* ctx, uint32 arg, void* address);
	[CLink] public static extern int32 asc_context_set_arg_object(Context* ctx, uint32 arg, void* obj);
	[CLink] public static extern int32 asc_context_execute(Context* ctx);
	[CLink] public static extern int32 asc_context_abort(Context* ctx);
	[CLink] public static extern int32 asc_context_get_state(Context* ctx);
	[CLink] public static extern uint8 asc_context_get_return_byte(Context* ctx);
	[CLink] public static extern uint16 asc_context_get_return_word(Context* ctx);
	[CLink] public static extern uint32 asc_context_get_return_dword(Context* ctx);
	[CLink] public static extern uint64 asc_context_get_return_qword(Context* ctx);
	[CLink] public static extern float asc_context_get_return_float(Context* ctx);
	[CLink] public static extern double asc_context_get_return_double(Context* ctx);
	[CLink] public static extern void* asc_context_get_return_address(Context* ctx);
	[CLink] public static extern void* asc_context_get_return_object(Context* ctx);
	[CLink] public static extern void* asc_context_get_address_of_return_value(Context* ctx);
	[CLink] public static extern char8* asc_context_get_exception_string(Context* ctx);
	[CLink] public static extern Function* asc_context_get_exception_function(Context* ctx);
	[CLink] public static extern int32 asc_context_get_exception_line_number(Context* ctx, int32* column, char8** section);
	[CLink] public static extern int32 asc_set_active_exception(char8* message);
	[CLink] public static extern Context* asc_get_active_context();
	[CLink] public static extern int32 asc_context_suspend(Context* ctx);

	// ---- debugging ----
	public typealias LineFn = function void(Context* ctx, void* user);
	[CLink] public static extern int32 asc_context_set_line_callback(Context* ctx, LineFn fn, void* user);
	[CLink] public static extern void asc_context_clear_line_callback(Context* ctx);
	[CLink] public static extern uint32 asc_context_get_callstack_size(Context* ctx);
	[CLink] public static extern Function* asc_context_get_function(Context* ctx, uint32 level);
	[CLink] public static extern int32 asc_context_get_line_number(Context* ctx, uint32 level, int32* column, char8** section);
	[CLink] public static extern int32 asc_context_get_var_count(Context* ctx, uint32 level);
	[CLink] public static extern int32 asc_context_get_var(Context* ctx, uint32 index, uint32 level, char8** name, int32* typeId);
	[CLink] public static extern char8* asc_context_get_var_declaration(Context* ctx, uint32 index, uint32 level);
	[CLink] public static extern void* asc_context_get_address_of_var(Context* ctx, uint32 index, uint32 level);
	[CLink] public static extern int32 asc_context_is_var_in_scope(Context* ctx, uint32 index, uint32 level);
	[CLink] public static extern int32 asc_context_get_this_type_id(Context* ctx, uint32 level);
	[CLink] public static extern void* asc_context_get_this_pointer(Context* ctx, uint32 level);
	[CLink] public static extern void* asc_context_get_user_data(Context* ctx);
	[CLink] public static extern void asc_context_set_user_data(Context* ctx, void* data);
	[CLink] public static extern void asc_function_add_ref(Function* fn);
	[CLink] public static extern void asc_function_release(Function* fn);
	[CLink] public static extern void* asc_function_get_delegate_object(Function* fn);
	[CLink] public static extern Function* asc_function_get_delegate_function(Function* fn);

	// ---- the generic call ----
	[CLink] public static extern Engine* asc_generic_get_engine(Generic* gen);
	[CLink] public static extern void* asc_generic_get_aux(Generic* gen);
	[CLink] public static extern Function* asc_generic_get_function(Generic* gen);
	[CLink] public static extern void* asc_generic_get_object(Generic* gen);
	[CLink] public static extern int32 asc_generic_get_object_type_id(Generic* gen);
	[CLink] public static extern int32 asc_generic_get_arg_count(Generic* gen);
	[CLink] public static extern int32 asc_generic_get_arg_type_id(Generic* gen, uint32 arg, uint32* flags);
	[CLink] public static extern uint8 asc_generic_get_arg_byte(Generic* gen, uint32 arg);
	[CLink] public static extern uint16 asc_generic_get_arg_word(Generic* gen, uint32 arg);
	[CLink] public static extern uint32 asc_generic_get_arg_dword(Generic* gen, uint32 arg);
	[CLink] public static extern uint64 asc_generic_get_arg_qword(Generic* gen, uint32 arg);
	[CLink] public static extern float asc_generic_get_arg_float(Generic* gen, uint32 arg);
	[CLink] public static extern double asc_generic_get_arg_double(Generic* gen, uint32 arg);
	[CLink] public static extern void* asc_generic_get_arg_address(Generic* gen, uint32 arg);
	[CLink] public static extern void* asc_generic_get_arg_object(Generic* gen, uint32 arg);
	[CLink] public static extern void* asc_generic_get_address_of_arg(Generic* gen, uint32 arg);
	[CLink] public static extern int32 asc_generic_get_return_type_id(Generic* gen, uint32* flags);
	[CLink] public static extern int32 asc_generic_set_return_byte(Generic* gen, uint8 value);
	[CLink] public static extern int32 asc_generic_set_return_word(Generic* gen, uint16 value);
	[CLink] public static extern int32 asc_generic_set_return_dword(Generic* gen, uint32 value);
	[CLink] public static extern int32 asc_generic_set_return_qword(Generic* gen, uint64 value);
	[CLink] public static extern int32 asc_generic_set_return_float(Generic* gen, float value);
	[CLink] public static extern int32 asc_generic_set_return_double(Generic* gen, double value);
	[CLink] public static extern int32 asc_generic_set_return_address(Generic* gen, void* address);
	[CLink] public static extern int32 asc_generic_set_return_object(Generic* gen, void* obj);
	[CLink] public static extern void* asc_generic_get_address_of_return_location(Generic* gen);

	// ---- script objects ----
	[CLink] public static extern ScriptObject* asc_engine_create_script_object(Engine* engine, TypeInfo* type);
	[CLink] public static extern void asc_object_add_ref(ScriptObject* obj);
	[CLink] public static extern void asc_object_release(ScriptObject* obj);
	[CLink] public static extern TypeInfo* asc_object_get_type(ScriptObject* obj);
	[CLink] public static extern uint32 asc_object_get_property_count(ScriptObject* obj);
	[CLink] public static extern int32 asc_object_get_property_type_id(ScriptObject* obj, uint32 index);
	[CLink] public static extern char8* asc_object_get_property_name(ScriptObject* obj, uint32 index);
	[CLink] public static extern void* asc_object_get_address_of_property(ScriptObject* obj, uint32 index);

	// ---- string and array ----
	[CLink] public static extern char8* asc_string_data(void* str, uint* length);
	[CLink] public static extern void asc_string_assign(void* str, char8* data, uint length);
	[CLink] public static extern void asc_string_construct(void* memory, char8* data, uint length);
	[CLink] public static extern void asc_string_destruct(void* str);
	[CLink] public static extern uint asc_string_size();
	[CLink] public static extern uint32 asc_array_get_size(void* arr);
	[CLink] public static extern void* asc_array_at(void* arr, uint32 index);
	[CLink] public static extern void asc_array_resize(void* arr, uint32 size);
	[CLink] public static extern int32 asc_array_get_element_type_id(void* arr);
	[CLink] public static extern void* asc_array_create(Engine* engine, char8* decl, uint32 length);
	[CLink] public static extern void asc_array_add_ref(void* arr);
	[CLink] public static extern void asc_array_release(void* arr);

	// ---- the constants the calls take, from angelscript.h ----

	// asERetCodes
	public const int32 asSUCCESS = 0;
	public const int32 asERROR = -1;
	public const int32 asINVALID_DECLARATION = -10;
	public const int32 asALREADY_REGISTERED = -13;
	public const int32 asNAME_TAKEN = -9;

	// asEObjTypeFlags
	public const uint64 asOBJ_REF = 1 << 0;
	public const uint64 asOBJ_VALUE = 1 << 1;
	public const uint64 asOBJ_GC = 1 << 2;
	public const uint64 asOBJ_POD = 1 << 3;
	public const uint64 asOBJ_NOHANDLE = 1 << 4;
	public const uint64 asOBJ_SCOPED = 1 << 5;
	public const uint64 asOBJ_TEMPLATE = 1 << 6;
	public const uint64 asOBJ_ASHANDLE = 1 << 7;
	public const uint64 asOBJ_APP_CLASS = 1 << 8;
	public const uint64 asOBJ_APP_CLASS_CONSTRUCTOR = 1 << 9;
	public const uint64 asOBJ_APP_CLASS_DESTRUCTOR = 1 << 10;
	public const uint64 asOBJ_APP_CLASS_ASSIGNMENT = 1 << 11;
	public const uint64 asOBJ_APP_CLASS_COPY_CONSTRUCTOR = 1 << 12;
	public const uint64 asOBJ_APP_PRIMITIVE = 1 << 13;
	public const uint64 asOBJ_APP_FLOAT = 1 << 14;
	public const uint64 asOBJ_APP_ARRAY = 1 << 15;
	public const uint64 asOBJ_APP_CLASS_ALLINTS = 1 << 16;
	public const uint64 asOBJ_APP_CLASS_ALLFLOATS = 1 << 17;
	public const uint64 asOBJ_NOCOUNT = 1 << 18;
	public const uint64 asOBJ_APP_CLASS_ALIGN8 = 1 << 19;
	public const uint64 asOBJ_IMPLICIT_HANDLE = 1 << 20;
	public const uint64 asOBJ_SCRIPT_OBJECT = 1 << 21;
	public const uint64 asOBJ_ENUM = 1 << 26;

	// asEBehaviours
	public const int32 asBEHAVE_CONSTRUCT = 0;
	public const int32 asBEHAVE_LIST_CONSTRUCT = 1;
	public const int32 asBEHAVE_DESTRUCT = 2;
	public const int32 asBEHAVE_FACTORY = 3;
	public const int32 asBEHAVE_LIST_FACTORY = 4;
	public const int32 asBEHAVE_ADDREF = 5;
	public const int32 asBEHAVE_RELEASE = 6;
	public const int32 asBEHAVE_GET_WEAKREF_FLAG = 7;

	// asEGMFlags
	public const int32 asGM_ONLY_IF_EXISTS = 0;
	public const int32 asGM_CREATE_IF_NOT_EXISTS = 1;
	public const int32 asGM_ALWAYS_CREATE = 2;

	// asEContextState
	public const int32 asEXECUTION_FINISHED = 0;
	public const int32 asEXECUTION_SUSPENDED = 1;
	public const int32 asEXECUTION_ABORTED = 2;
	public const int32 asEXECUTION_EXCEPTION = 3;
	public const int32 asEXECUTION_PREPARED = 4;
	public const int32 asEXECUTION_UNINITIALIZED = 5;
	public const int32 asEXECUTION_ACTIVE = 6;
	public const int32 asEXECUTION_ERROR = 7;

	// asEMsgType
	public const int32 asMSGTYPE_ERROR = 0;
	public const int32 asMSGTYPE_WARNING = 1;
	public const int32 asMSGTYPE_INFORMATION = 2;

	// asETypeIdFlags
	public const int32 asTYPEID_VOID = 0;
	public const int32 asTYPEID_BOOL = 1;
	public const int32 asTYPEID_INT8 = 2;
	public const int32 asTYPEID_INT16 = 3;
	public const int32 asTYPEID_INT32 = 4;
	public const int32 asTYPEID_INT64 = 5;
	public const int32 asTYPEID_UINT8 = 6;
	public const int32 asTYPEID_UINT16 = 7;
	public const int32 asTYPEID_UINT32 = 8;
	public const int32 asTYPEID_UINT64 = 9;
	public const int32 asTYPEID_FLOAT = 10;
	public const int32 asTYPEID_DOUBLE = 11;
	public const int32 asTYPEID_OBJHANDLE = 0x40000000;
	public const int32 asTYPEID_HANDLETOCONST = 0x20000000;
	public const int32 asTYPEID_MASK_OBJECT = 0x1C000000;
	public const int32 asTYPEID_APPOBJECT = 0x04000000;
	public const int32 asTYPEID_SCRIPTOBJECT = 0x08000000;
	public const int32 asTYPEID_TEMPLATE = 0x10000000;
	public const int32 asTYPEID_MASK_SEQNBR = 0x03FFFFFF;

	// asETypeModifiers
	public const uint32 asTM_NONE = 0;
	public const uint32 asTM_INREF = 1;
	public const uint32 asTM_OUTREF = 2;
	public const uint32 asTM_INOUTREF = 3;
	public const uint32 asTM_CONST = 4;

	// asEEngineProp
	public const int32 asEP_ALLOW_UNSAFE_REFERENCES = 1;
	public const int32 asEP_OPTIMIZE_BYTECODE = 2;
	public const int32 asEP_COPY_SCRIPT_SECTIONS = 3;
	public const int32 asEP_MAX_STACK_SIZE = 4;
	public const int32 asEP_USE_CHARACTER_LITERALS = 5;
	public const int32 asEP_ALLOW_MULTILINE_STRINGS = 6;
	public const int32 asEP_ALLOW_IMPLICIT_HANDLE_TYPES = 7;
	public const int32 asEP_BUILD_WITHOUT_LINE_CUES = 8;
	public const int32 asEP_INIT_GLOBAL_VARS_AFTER_BUILD = 9;
	public const int32 asEP_REQUIRE_ENUM_SCOPE = 10;
	public const int32 asEP_GENERIC_CALL_MODE = 28;
}
