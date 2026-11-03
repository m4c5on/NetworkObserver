import Foundation

/// Plain-language names and explanations for HTTP status codes, shown when a status code on a
/// site card is clicked.
nonisolated enum HTTPStatusDescription {
    static func name(for code: Int) -> String {
        known[code]?.name ?? classDescription(for: code).name
    }

    static func explanation(for code: Int) -> String {
        known[code]?.explanation ?? classDescription(for: code).explanation
    }

    private typealias Entry = (name: String, explanation: String)

    private static func classDescription(for code: Int) -> Entry {
        switch code {
        case 100..<200:
            ("Informational", "An interim response: the server received the request and is still working on it.")
        case 200..<300:
            ("Success", "The server received and handled the request successfully.")
        case 300..<400:
            ("Redirection", "The resource lives somewhere else; the response points to the new location.")
        case 400..<500:
            ("Client Error", "The server is up but rejected the request itself — something about the request (URL, method, headers or body) is wrong for this endpoint.")
        case 500..<600:
            ("Server Error", "The request reached the server, but the server failed while handling it. The problem is on the service side.")
        default:
            ("Unknown", "This is not a standard HTTP status code.")
        }
    }

    private static let known: [Int: Entry] = [
        100: ("Continue", "The server got the request headers and the client can send the body."),
        101: ("Switching Protocols", "The server is switching to another protocol, e.g. WebSocket."),
        200: ("OK", "Everything worked: the server handled the request and returned a result."),
        201: ("Created", "The request succeeded and created a new resource. Usual for POST."),
        202: ("Accepted", "The request was accepted for processing, which will finish later."),
        204: ("No Content", "The request succeeded and there is intentionally nothing in the response body. Usual for PATCH, PUT and DELETE."),
        301: ("Moved Permanently", "The address changed for good; the response points to the new one. Update the link to the new address."),
        302: ("Found", "A temporary redirect to another address — often to a login page."),
        303: ("See Other", "The result should be fetched from another address with GET."),
        304: ("Not Modified", "The cached copy is still valid, so the server sent no body."),
        307: ("Temporary Redirect", "A temporary redirect that keeps the same method and body."),
        308: ("Permanent Redirect", "A permanent redirect that keeps the same method and body."),
        400: ("Bad Request", "The server is up but couldn't understand the request: a required parameter or body is missing or malformed."),
        401: ("Unauthorized", "The server is up, but the endpoint needs authentication and the request had no valid token or credentials. Without a token this is the normal answer for a protected API — add 401 to the accepted codes to treat it as \"online\"."),
        403: ("Forbidden", "The server is up and knows who you are (or doesn't care), but access to this resource is not allowed."),
        404: ("Not Found", "The server is up, but nothing exists at this path. Check the URL, or the route was removed or renamed."),
        405: ("Method Not Allowed", "The path exists but doesn't accept this HTTP method — e.g. sending GET to an endpoint that only takes POST."),
        406: ("Not Acceptable", "The server can't produce a response in the format the request asked for."),
        408: ("Request Timeout", "The server got tired of waiting for the request to finish arriving."),
        409: ("Conflict", "The request conflicts with the current state of the resource, e.g. a duplicate or an edit clash."),
        410: ("Gone", "The resource was here but has been removed for good."),
        413: ("Content Too Large", "The request body is bigger than the server allows."),
        415: ("Unsupported Media Type", "The server doesn't accept the body's format — usually a wrong or missing Content-Type."),
        418: ("I'm a Teapot", "A joke code from an April Fools' RFC; some servers use it to reject bots."),
        422: ("Unprocessable Content", "The request was well-formed but failed validation — e.g. a required field was missing. The endpoint itself is working."),
        429: ("Too Many Requests", "Rate limit: too many requests in a short time. The server is up but asks to slow down."),
        500: ("Internal Server Error", "The server crashed or hit an unhandled error while handling the request. The bug is in the service."),
        501: ("Not Implemented", "The server doesn't support what the request needs, e.g. this method."),
        502: ("Bad Gateway", "A proxy or gateway in front of the service got an invalid answer from it — the service behind it is often down or restarting."),
        503: ("Service Unavailable", "The service is temporarily unable to handle requests — overloaded, in maintenance or still starting."),
        504: ("Gateway Timeout", "A proxy or gateway in front of the service didn't get an answer from it in time — the service is hanging or very slow."),
    ]
}
