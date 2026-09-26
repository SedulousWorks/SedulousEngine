/* The C interface over AngelScript for Beef. See angelscript_beef.h. */

#include "angelscript_beef.h"

#include <angelscript.h>
#include <new>
#include <string>
#include <vector>

#include "add_on/scriptarray/scriptarray.h"
#include "add_on/scriptstdstring/scriptstdstring.h"
#include "add_on/scriptbuilder/scriptbuilder.h"

namespace
{
	/* The host's trampoline target and the message sink, kept on the engine as user data. */
	struct EngineHooks
	{
		asc_generic_fn generic = nullptr;
		void* genericUser = nullptr;
		asc_message_fn message = nullptr;
		void* messageUser = nullptr;
	};

	const asPWORD kHooksKey = 0x5ED0;

	EngineHooks* Hooks(asIScriptEngine* engine)
	{
		return static_cast<EngineHooks*>(engine->GetUserData(kHooksKey));
	}

	/* Every generic call lands here and is forwarded with its auxiliary. */
	void Trampoline(asIScriptGeneric* gen)
	{
		EngineHooks* hooks = Hooks(gen->GetEngine());
		if (hooks != nullptr && hooks->generic != nullptr)
			hooks->generic(reinterpret_cast<asc_generic*>(gen), gen->GetAuxiliary(), hooks->genericUser);
	}

	void MessageCallback(const asSMessageInfo* msg, void* param)
	{
		EngineHooks* hooks = static_cast<EngineHooks*>(param);
		if (hooks != nullptr && hooks->message != nullptr)
			hooks->message(msg->section, msg->row, msg->col, msg->type, msg->message, hooks->messageUser);
	}

	void HooksCleanup(asIScriptEngine* engine)
	{
		delete Hooks(engine);
	}

	inline asIScriptEngine*   E(asc_engine* e)     { return reinterpret_cast<asIScriptEngine*>(e); }
	inline asIScriptModule*   M(asc_module* m)     { return reinterpret_cast<asIScriptModule*>(m); }
	inline asIScriptContext*  C(asc_context* c)    { return reinterpret_cast<asIScriptContext*>(c); }
	inline asIScriptFunction* F(asc_function* f)   { return reinterpret_cast<asIScriptFunction*>(f); }
	inline asITypeInfo*       T(asc_typeinfo* t)   { return reinterpret_cast<asITypeInfo*>(t); }
	inline asIScriptGeneric*  G(asc_generic* g)    { return reinterpret_cast<asIScriptGeneric*>(g); }
	inline asIScriptObject*   O(asc_object* o)     { return reinterpret_cast<asIScriptObject*>(o); }
	inline asc_typeinfo*      Wrap(asITypeInfo* t) { return reinterpret_cast<asc_typeinfo*>(t); }
	inline asc_function*      Wrap(asIScriptFunction* f) { return reinterpret_cast<asc_function*>(f); }
}

extern "C" {

/* ---- engine ---- */

asc_engine* asc_engine_create(void)
{
	asIScriptEngine* engine = asCreateScriptEngine();
	if (engine == nullptr)
		return nullptr;
	engine->SetUserData(new EngineHooks(), kHooksKey);
	engine->SetEngineUserDataCleanupCallback(HooksCleanup, kHooksKey);
	return reinterpret_cast<asc_engine*>(engine);
}

void asc_engine_release(asc_engine* engine)
{
	if (engine != nullptr)
		E(engine)->ShutDownAndRelease();
}

void asc_engine_set_message_callback(asc_engine* engine, asc_message_fn fn, void* user)
{
	EngineHooks* hooks = Hooks(E(engine));
	hooks->message = fn;
	hooks->messageUser = user;
	E(engine)->SetMessageCallback(asFUNCTION(MessageCallback), hooks, asCALL_CDECL);
}

void asc_engine_set_generic_callback(asc_engine* engine, asc_generic_fn fn, void* user)
{
	EngineHooks* hooks = Hooks(E(engine));
	hooks->generic = fn;
	hooks->genericUser = user;
}

int asc_engine_set_property(asc_engine* engine, int property, size_t value)
{
	return E(engine)->SetEngineProperty(static_cast<asEEngineProp>(property), static_cast<asPWORD>(value));
}

void asc_engine_register_std_string(asc_engine* engine)
{
	RegisterStdString(E(engine));
}

/* The string utilities (split, join) need array<T>, so they come with it; register the
 * string first. */
void asc_engine_register_script_array(asc_engine* engine, int defaultArray)
{
	RegisterScriptArray(E(engine), defaultArray != 0);
	if (E(engine)->GetTypeInfoByName("string") != nullptr)
		RegisterStdStringUtils(E(engine));
}

int asc_engine_set_default_namespace(asc_engine* engine, const char* ns)
{
	return E(engine)->SetDefaultNamespace(ns);
}

/* ---- registration ---- */

int asc_engine_register_object_type(asc_engine* engine, const char* name, int byteSize, uint64_t flags)
{
	return E(engine)->RegisterObjectType(name, byteSize, static_cast<asQWORD>(flags));
}

int asc_engine_register_object_method(asc_engine* engine, const char* obj, const char* decl, void* aux)
{
	return E(engine)->RegisterObjectMethod(obj, decl, asFUNCTION(Trampoline), asCALL_GENERIC, aux);
}

int asc_engine_register_object_behaviour(asc_engine* engine, const char* obj, int behaviour, const char* decl, void* aux)
{
	return E(engine)->RegisterObjectBehaviour(obj, static_cast<asEBehaviours>(behaviour), decl, asFUNCTION(Trampoline), asCALL_GENERIC, aux);
}

int asc_engine_register_object_property(asc_engine* engine, const char* obj, const char* decl, int byteOffset)
{
	return E(engine)->RegisterObjectProperty(obj, decl, byteOffset);
}

int asc_engine_register_global_function(asc_engine* engine, const char* decl, void* aux)
{
	return E(engine)->RegisterGlobalFunction(decl, asFUNCTION(Trampoline), asCALL_GENERIC, aux);
}

int asc_engine_register_global_property(asc_engine* engine, const char* decl, void* pointer)
{
	return E(engine)->RegisterGlobalProperty(decl, pointer);
}

int asc_engine_register_enum(asc_engine* engine, const char* name)
{
	return E(engine)->RegisterEnum(name);
}

int asc_engine_register_enum_value(asc_engine* engine, const char* type, const char* name, int value)
{
	return E(engine)->RegisterEnumValue(type, name, value);
}

int asc_engine_register_funcdef(asc_engine* engine, const char* decl)
{
	return E(engine)->RegisterFuncdef(decl);
}

int asc_engine_register_interface(asc_engine* engine, const char* name)
{
	return E(engine)->RegisterInterface(name);
}

int asc_engine_register_interface_method(asc_engine* engine, const char* intf, const char* decl)
{
	return E(engine)->RegisterInterfaceMethod(intf, decl);
}

/* ---- types ---- */

int asc_engine_get_type_id_by_decl(asc_engine* engine, const char* decl) { return E(engine)->GetTypeIdByDecl(decl); }
asc_typeinfo* asc_engine_get_type_info_by_name(asc_engine* engine, const char* name) { return Wrap(E(engine)->GetTypeInfoByName(name)); }
asc_typeinfo* asc_engine_get_type_info_by_decl(asc_engine* engine, const char* decl) { return Wrap(E(engine)->GetTypeInfoByDecl(decl)); }
asc_typeinfo* asc_engine_get_type_info_by_id(asc_engine* engine, int typeId) { return Wrap(E(engine)->GetTypeInfoById(typeId)); }
const char* asc_engine_get_type_declaration(asc_engine* engine, int typeId, int includeNamespace) { return E(engine)->GetTypeDeclaration(typeId, includeNamespace != 0); }
const char* asc_typeinfo_get_name(asc_typeinfo* type) { return T(type)->GetName(); }
const char* asc_typeinfo_get_namespace(asc_typeinfo* type) { return T(type)->GetNamespace(); }
int asc_typeinfo_get_type_id(asc_typeinfo* type) { return T(type)->GetTypeId(); }
uint64_t asc_typeinfo_get_flags(asc_typeinfo* type) { return static_cast<uint64_t>(T(type)->GetFlags()); }
int asc_typeinfo_get_size(asc_typeinfo* type) { return static_cast<int>(T(type)->GetSize()); }
asc_typeinfo* asc_typeinfo_get_base_type(asc_typeinfo* type) { return Wrap(T(type)->GetBaseType()); }
int asc_typeinfo_implements(asc_typeinfo* type, asc_typeinfo* intf) { return T(type)->Implements(T(intf)) ? 1 : 0; }
unsigned asc_typeinfo_get_method_count(asc_typeinfo* type) { return T(type)->GetMethodCount(); }
asc_function* asc_typeinfo_get_method_by_index(asc_typeinfo* type, unsigned index) { return Wrap(T(type)->GetMethodByIndex(index)); }
asc_function* asc_typeinfo_get_method_by_decl(asc_typeinfo* type, const char* decl) { return Wrap(T(type)->GetMethodByDecl(decl)); }
asc_function* asc_typeinfo_get_method_by_name(asc_typeinfo* type, const char* name) { return Wrap(T(type)->GetMethodByName(name)); }
unsigned asc_typeinfo_get_factory_count(asc_typeinfo* type) { return T(type)->GetFactoryCount(); }
asc_function* asc_typeinfo_get_factory_by_index(asc_typeinfo* type, unsigned index) { return Wrap(T(type)->GetFactoryByIndex(index)); }
asc_function* asc_typeinfo_get_factory_by_decl(asc_typeinfo* type, const char* decl) { return Wrap(T(type)->GetFactoryByDecl(decl)); }
unsigned asc_typeinfo_get_property_count(asc_typeinfo* type) { return T(type)->GetPropertyCount(); }

int asc_typeinfo_get_property(asc_typeinfo* type, unsigned index, const char** name, int* typeId, int* offset)
{
	return T(type)->GetProperty(index, name, typeId, nullptr, nullptr, offset);
}
int asc_typeinfo_get_property_access(asc_typeinfo* type, unsigned index, int* isPrivate, int* isProtected)
{
	bool priv = false, prot = false;
	int r = T(type)->GetProperty(index, nullptr, nullptr, &priv, &prot);
	if (isPrivate != nullptr) *isPrivate = priv ? 1 : 0;
	if (isProtected != nullptr) *isProtected = prot ? 1 : 0;
	return r;
}

/* ---- functions ---- */

const char* asc_function_get_name(asc_function* fn) { return F(fn)->GetName(); }
const char* asc_function_get_declaration(asc_function* fn, int includeObjectName, int includeNamespace, int includeParamNames)
{
	return F(fn)->GetDeclaration(includeObjectName != 0, includeNamespace != 0, includeParamNames != 0);
}
unsigned asc_function_get_param_count(asc_function* fn) { return F(fn)->GetParamCount(); }
int asc_function_get_param(asc_function* fn, unsigned index, int* typeId, uint32_t* flags, const char** name)
{
	asDWORD f = 0;
	int r = F(fn)->GetParam(index, typeId, &f, name);
	if (flags != nullptr)
		*flags = f;
	return r;
}
int asc_function_get_return_type_id(asc_function* fn, uint32_t* flags)
{
	asDWORD f = 0;
	int id = F(fn)->GetReturnTypeId(&f);
	if (flags != nullptr)
		*flags = f;
	return id;
}
asc_typeinfo* asc_function_get_object_type(asc_function* fn) { return Wrap(F(fn)->GetObjectType()); }

/* ---- modules ---- */

asc_module* asc_engine_get_module(asc_engine* engine, const char* name, int flags)
{
	return reinterpret_cast<asc_module*>(E(engine)->GetModule(name, static_cast<asEGMFlags>(flags)));
}
void asc_module_discard(asc_module* module) { M(module)->Discard(); }
const char* asc_module_get_name(asc_module* module) { return M(module)->GetName(); }
int asc_module_add_script_section(asc_module* module, const char* name, const char* code, size_t length)
{
	return M(module)->AddScriptSection(name, code, length);
}
int asc_module_build(asc_module* module) { return M(module)->Build(); }
unsigned asc_module_get_function_count(asc_module* module) { return M(module)->GetFunctionCount(); }
asc_function* asc_module_get_function_by_index(asc_module* module, unsigned index) { return Wrap(M(module)->GetFunctionByIndex(index)); }
asc_function* asc_module_get_function_by_decl(asc_module* module, const char* decl) { return Wrap(M(module)->GetFunctionByDecl(decl)); }
asc_function* asc_module_get_function_by_name(asc_module* module, const char* name) { return Wrap(M(module)->GetFunctionByName(name)); }
unsigned asc_module_get_object_type_count(asc_module* module) { return M(module)->GetObjectTypeCount(); }
asc_typeinfo* asc_module_get_object_type_by_index(asc_module* module, unsigned index) { return Wrap(M(module)->GetObjectTypeByIndex(index)); }
asc_typeinfo* asc_module_get_type_info_by_name(asc_module* module, const char* name) { return Wrap(M(module)->GetTypeInfoByName(name)); }
asc_typeinfo* asc_module_get_type_info_by_decl(asc_module* module, const char* decl) { return Wrap(M(module)->GetTypeInfoByDecl(decl)); }
unsigned asc_module_get_global_var_count(asc_module* module) { return M(module)->GetGlobalVarCount(); }
void* asc_module_get_address_of_global_var(asc_module* module, unsigned index) { return M(module)->GetAddressOfGlobalVar(index); }

/* ---- contexts ---- */

asc_context* asc_engine_create_context(asc_engine* engine) { return reinterpret_cast<asc_context*>(E(engine)->CreateContext()); }
void asc_context_release(asc_context* ctx) { if (ctx != nullptr) C(ctx)->Release(); }
int asc_context_prepare(asc_context* ctx, asc_function* fn) { return C(ctx)->Prepare(F(fn)); }
int asc_context_unprepare(asc_context* ctx) { return C(ctx)->Unprepare(); }
int asc_context_set_object(asc_context* ctx, void* obj) { return C(ctx)->SetObject(obj); }
int asc_context_set_arg_byte(asc_context* ctx, unsigned arg, uint8_t value) { return C(ctx)->SetArgByte(arg, value); }
int asc_context_set_arg_word(asc_context* ctx, unsigned arg, uint16_t value) { return C(ctx)->SetArgWord(arg, value); }
int asc_context_set_arg_dword(asc_context* ctx, unsigned arg, uint32_t value) { return C(ctx)->SetArgDWord(arg, value); }
int asc_context_set_arg_qword(asc_context* ctx, unsigned arg, uint64_t value) { return C(ctx)->SetArgQWord(arg, value); }
int asc_context_set_arg_float(asc_context* ctx, unsigned arg, float value) { return C(ctx)->SetArgFloat(arg, value); }
int asc_context_set_arg_double(asc_context* ctx, unsigned arg, double value) { return C(ctx)->SetArgDouble(arg, value); }
int asc_context_set_arg_address(asc_context* ctx, unsigned arg, void* address) { return C(ctx)->SetArgAddress(arg, address); }
int asc_context_set_arg_object(asc_context* ctx, unsigned arg, void* obj) { return C(ctx)->SetArgObject(arg, obj); }
int asc_context_execute(asc_context* ctx) { return C(ctx)->Execute(); }
int asc_context_abort(asc_context* ctx) { return C(ctx)->Abort(); }
int asc_context_get_state(asc_context* ctx) { return C(ctx)->GetState(); }
uint8_t asc_context_get_return_byte(asc_context* ctx) { return C(ctx)->GetReturnByte(); }
uint16_t asc_context_get_return_word(asc_context* ctx) { return C(ctx)->GetReturnWord(); }
uint32_t asc_context_get_return_dword(asc_context* ctx) { return C(ctx)->GetReturnDWord(); }
uint64_t asc_context_get_return_qword(asc_context* ctx) { return C(ctx)->GetReturnQWord(); }
float asc_context_get_return_float(asc_context* ctx) { return C(ctx)->GetReturnFloat(); }
double asc_context_get_return_double(asc_context* ctx) { return C(ctx)->GetReturnDouble(); }
void* asc_context_get_return_address(asc_context* ctx) { return C(ctx)->GetReturnAddress(); }
void* asc_context_get_return_object(asc_context* ctx) { return C(ctx)->GetReturnObject(); }
void* asc_context_get_address_of_return_value(asc_context* ctx) { return C(ctx)->GetAddressOfReturnValue(); }
const char* asc_context_get_exception_string(asc_context* ctx) { return C(ctx)->GetExceptionString(); }
asc_function* asc_context_get_exception_function(asc_context* ctx) { return Wrap(C(ctx)->GetExceptionFunction()); }
int asc_context_get_exception_line_number(asc_context* ctx, int* column, const char** section)
{
	return C(ctx)->GetExceptionLineNumber(column, section);
}

int asc_set_active_exception(const char* message)
{
	asIScriptContext* ctx = asGetActiveContext();
	return (ctx != nullptr) ? ctx->SetException(message) : asERROR;
}
asc_context* asc_get_active_context(void) { return reinterpret_cast<asc_context*>(asGetActiveContext()); }
int asc_context_suspend(asc_context* ctx) { return C(ctx)->Suspend(); }

/* ---- debugging ---- */

namespace
{
	struct LineHooks
	{
		asc_line_fn fn;
		void* user;
	};

	void LineCallback(asIScriptContext* ctx, void* obj)
	{
		LineHooks* hooks = static_cast<LineHooks*>(obj);
		if (hooks != nullptr && hooks->fn != nullptr)
			hooks->fn(reinterpret_cast<asc_context*>(ctx), hooks->user);
	}

	/* One hook record per context, kept in the context's user data slot 1 so the shim can free
	   it on clear. Slot 0 stays the host's (asc_context_set_user_data). */
	const asPWORD kLineHooksSlot = 1;
}

int asc_context_set_line_callback(asc_context* ctx, asc_line_fn fn, void* user)
{
	asIScriptContext* c = C(ctx);
	LineHooks* hooks = static_cast<LineHooks*>(c->GetUserData(kLineHooksSlot));
	if (hooks == nullptr)
	{
		hooks = new LineHooks();
		c->SetUserData(hooks, kLineHooksSlot);
	}
	hooks->fn = fn;
	hooks->user = user;
	return c->SetLineCallback(asFUNCTION(LineCallback), hooks, asCALL_CDECL);
}

void asc_context_clear_line_callback(asc_context* ctx)
{
	asIScriptContext* c = C(ctx);
	c->ClearLineCallback();
	LineHooks* hooks = static_cast<LineHooks*>(c->GetUserData(kLineHooksSlot));
	if (hooks != nullptr)
	{
		delete hooks;
		c->SetUserData(nullptr, kLineHooksSlot);
	}
}

unsigned asc_context_get_callstack_size(asc_context* ctx) { return C(ctx)->GetCallstackSize(); }
asc_function* asc_context_get_function(asc_context* ctx, unsigned level) { return Wrap(C(ctx)->GetFunction(level)); }
int asc_context_get_line_number(asc_context* ctx, unsigned level, int* column, const char** section) { return C(ctx)->GetLineNumber(level, column, section); }
int asc_context_get_var_count(asc_context* ctx, unsigned level) { return C(ctx)->GetVarCount(level); }
int asc_context_get_var(asc_context* ctx, unsigned index, unsigned level, const char** name, int* typeId) { return C(ctx)->GetVar(index, level, name, typeId); }
const char* asc_context_get_var_declaration(asc_context* ctx, unsigned index, unsigned level) { return C(ctx)->GetVarDeclaration(index, level, false); }
void* asc_context_get_address_of_var(asc_context* ctx, unsigned index, unsigned level) { return C(ctx)->GetAddressOfVar(index, level); }
int asc_context_is_var_in_scope(asc_context* ctx, unsigned index, unsigned level) { return C(ctx)->IsVarInScope(index, level) ? 1 : 0; }
int asc_context_get_this_type_id(asc_context* ctx, unsigned level) { return C(ctx)->GetThisTypeId(level); }
void* asc_context_get_this_pointer(asc_context* ctx, unsigned level) { return C(ctx)->GetThisPointer(level); }
void* asc_context_get_user_data(asc_context* ctx) { return C(ctx)->GetUserData(); }
void asc_context_set_user_data(asc_context* ctx, void* data) { C(ctx)->SetUserData(data); }

void asc_function_add_ref(asc_function* fn) { F(fn)->AddRef(); }
void asc_function_release(asc_function* fn) { F(fn)->Release(); }
void* asc_function_get_delegate_object(asc_function* fn) { return F(fn)->GetDelegateObject(); }
asc_function* asc_function_get_delegate_function(asc_function* fn) { return Wrap(F(fn)->GetDelegateFunction()); }

/* ---- the generic call ---- */

asc_engine* asc_generic_get_engine(asc_generic* gen) { return reinterpret_cast<asc_engine*>(G(gen)->GetEngine()); }
void* asc_generic_get_aux(asc_generic* gen) { return G(gen)->GetAuxiliary(); }
asc_function* asc_generic_get_function(asc_generic* gen) { return Wrap(G(gen)->GetFunction()); }
void* asc_generic_get_object(asc_generic* gen) { return G(gen)->GetObject(); }
int asc_generic_get_object_type_id(asc_generic* gen) { return G(gen)->GetObjectTypeId(); }
int asc_generic_get_arg_count(asc_generic* gen) { return G(gen)->GetArgCount(); }
int asc_generic_get_arg_type_id(asc_generic* gen, unsigned arg, uint32_t* flags)
{
	asDWORD f = 0;
	int id = G(gen)->GetArgTypeId(arg, &f);
	if (flags != nullptr)
		*flags = f;
	return id;
}
uint8_t asc_generic_get_arg_byte(asc_generic* gen, unsigned arg) { return G(gen)->GetArgByte(arg); }
uint16_t asc_generic_get_arg_word(asc_generic* gen, unsigned arg) { return G(gen)->GetArgWord(arg); }
uint32_t asc_generic_get_arg_dword(asc_generic* gen, unsigned arg) { return G(gen)->GetArgDWord(arg); }
uint64_t asc_generic_get_arg_qword(asc_generic* gen, unsigned arg) { return G(gen)->GetArgQWord(arg); }
float asc_generic_get_arg_float(asc_generic* gen, unsigned arg) { return G(gen)->GetArgFloat(arg); }
double asc_generic_get_arg_double(asc_generic* gen, unsigned arg) { return G(gen)->GetArgDouble(arg); }
void* asc_generic_get_arg_address(asc_generic* gen, unsigned arg) { return G(gen)->GetArgAddress(arg); }
void* asc_generic_get_arg_object(asc_generic* gen, unsigned arg) { return G(gen)->GetArgObject(arg); }
void* asc_generic_get_address_of_arg(asc_generic* gen, unsigned arg) { return G(gen)->GetAddressOfArg(arg); }
int asc_generic_get_return_type_id(asc_generic* gen, uint32_t* flags)
{
	asDWORD f = 0;
	int id = G(gen)->GetReturnTypeId(&f);
	if (flags != nullptr)
		*flags = f;
	return id;
}
int asc_generic_set_return_byte(asc_generic* gen, uint8_t value) { return G(gen)->SetReturnByte(value); }
int asc_generic_set_return_word(asc_generic* gen, uint16_t value) { return G(gen)->SetReturnWord(value); }
int asc_generic_set_return_dword(asc_generic* gen, uint32_t value) { return G(gen)->SetReturnDWord(value); }
int asc_generic_set_return_qword(asc_generic* gen, uint64_t value) { return G(gen)->SetReturnQWord(value); }
int asc_generic_set_return_float(asc_generic* gen, float value) { return G(gen)->SetReturnFloat(value); }
int asc_generic_set_return_double(asc_generic* gen, double value) { return G(gen)->SetReturnDouble(value); }
int asc_generic_set_return_address(asc_generic* gen, void* address) { return G(gen)->SetReturnAddress(address); }
int asc_generic_set_return_object(asc_generic* gen, void* obj) { return G(gen)->SetReturnObject(obj); }
void* asc_generic_get_address_of_return_location(asc_generic* gen) { return G(gen)->GetAddressOfReturnLocation(); }

/* ---- script objects ---- */

asc_object* asc_engine_create_script_object(asc_engine* engine, asc_typeinfo* type)
{
	return reinterpret_cast<asc_object*>(E(engine)->CreateScriptObject(T(type)));
}
void asc_object_add_ref(asc_object* obj) { O(obj)->AddRef(); }
void asc_object_release(asc_object* obj) { O(obj)->Release(); }
asc_typeinfo* asc_object_get_type(asc_object* obj) { return Wrap(O(obj)->GetObjectType()); }
unsigned asc_object_get_property_count(asc_object* obj) { return O(obj)->GetPropertyCount(); }
int asc_object_get_property_type_id(asc_object* obj, unsigned index) { return O(obj)->GetPropertyTypeId(index); }
const char* asc_object_get_property_name(asc_object* obj, unsigned index) { return O(obj)->GetPropertyName(index); }
void* asc_object_get_address_of_property(asc_object* obj, unsigned index) { return O(obj)->GetAddressOfProperty(index); }

/* ---- string ---- */

const char* asc_string_data(const void* str, size_t* length)
{
	const std::string* s = static_cast<const std::string*>(str);
	if (length != nullptr)
		*length = s->size();
	return s->data();
}
void asc_string_assign(void* str, const char* data, size_t length) { static_cast<std::string*>(str)->assign(data, length); }
void asc_string_construct(void* memory, const char* data, size_t length) { new (memory) std::string(data, length); }
void asc_string_destruct(void* str) { static_cast<std::string*>(str)->~basic_string(); }
size_t asc_string_size(void) { return sizeof(std::string); }

/* ---- array ---- */

unsigned asc_array_get_size(const void* arr) { return static_cast<const CScriptArray*>(arr)->GetSize(); }
void* asc_array_at(void* arr, unsigned index) { return static_cast<CScriptArray*>(arr)->At(index); }
void asc_array_resize(void* arr, unsigned size) { static_cast<CScriptArray*>(arr)->Resize(size); }
int asc_array_get_element_type_id(const void* arr) { return static_cast<const CScriptArray*>(arr)->GetElementTypeId(); }
void* asc_array_create(asc_engine* engine, const char* decl, unsigned length)
{
	asITypeInfo* type = E(engine)->GetTypeInfoByDecl(decl);
	return (type != nullptr) ? CScriptArray::Create(type, length) : nullptr;
}
void asc_array_add_ref(void* arr) { static_cast<CScriptArray*>(arr)->AddRef(); }
void asc_array_release(void* arr) { static_cast<CScriptArray*>(arr)->Release(); }

/* ---- script builder ---- */

struct asc_builder
{
	CScriptBuilder builder;
	/* The last metadata query's entries, so a returned pointer outlives the call. */
	std::vector<std::string> metadata;
};

static int RefuseInclude(const char*, const char*, CScriptBuilder*, void*)
{
	return -1;
}

asc_builder* asc_builder_create(void)
{
	asc_builder* b = new (std::nothrow) asc_builder();
	if (b != nullptr)
		b->builder.SetIncludeCallback(RefuseInclude, nullptr);
	return b;
}
void asc_builder_destroy(asc_builder* builder) { delete builder; }
int asc_builder_start_module(asc_builder* builder, asc_engine* engine, const char* moduleName)
{
	return builder->builder.StartNewModule(E(engine), moduleName);
}
int asc_builder_add_section(asc_builder* builder, const char* name, const char* code, size_t length)
{
	return builder->builder.AddSectionFromMemory(name, code, static_cast<unsigned>(length), 0);
}
int asc_builder_build(asc_builder* builder) { return builder->builder.BuildModule(); }
asc_module* asc_builder_get_module(asc_builder* builder)
{
	return reinterpret_cast<asc_module*>(builder->builder.GetModule());
}
int asc_builder_property_metadata_count(asc_builder* builder, int typeId, int propertyIndex)
{
	builder->metadata = builder->builder.GetMetadataForTypeProperty(typeId, propertyIndex);
	return static_cast<int>(builder->metadata.size());
}
const char* asc_builder_property_metadata(asc_builder* builder, int typeId, int propertyIndex, int entry)
{
	builder->metadata = builder->builder.GetMetadataForTypeProperty(typeId, propertyIndex);
	if (entry < 0 || entry >= static_cast<int>(builder->metadata.size()))
		return nullptr;
	return builder->metadata[static_cast<size_t>(entry)].c_str();
}

} // extern "C"
