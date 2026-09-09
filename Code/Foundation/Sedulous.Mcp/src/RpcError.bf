namespace Sedulous.Mcp;

/// The JSON-RPC error codes this server emits. The numbers are fixed by the specification.
enum RpcError : int32
{
	case ParseError = -32700;
	case InvalidRequest = -32600;
	case MethodNotFound = -32601;
	case InvalidParams = -32602;
	case InternalError = -32603;
}
