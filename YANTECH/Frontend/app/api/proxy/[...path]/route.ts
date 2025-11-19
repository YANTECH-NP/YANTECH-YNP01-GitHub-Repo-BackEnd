import { NextResponse } from "next/server";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

function extractPathSegments(request: Request) {
  const url = new URL(request.url);
  const after = url.pathname.replace(/^\/api\/proxy\//, "");
  const segments = after ? after.split("/").filter(Boolean) : [];
  return segments;
}

export async function GET(request: Request) {
  const segments = extractPathSegments(request);
  return proxyRequest(request, segments, "GET");
}

export async function POST(request: Request) {
  const segments = extractPathSegments(request);
  return proxyRequest(request, segments, "POST");
}

export async function PUT(request: Request) {
  const segments = extractPathSegments(request);
  return proxyRequest(request, segments, "PUT");
}

export async function DELETE(request: Request) {
  const segments = extractPathSegments(request);
  return proxyRequest(request, segments, "DELETE");
}

export async function PATCH(request: Request) {
  const segments = extractPathSegments(request);
  return proxyRequest(request, segments, "PATCH");
}

async function proxyRequest(
  request: Request,
  pathSegments: string[],
  method: string
) {
  try {
    const path = pathSegments.join("/");
    const qs = request.url.includes("?") ? "?" + request.url.split("?")[1] : "";
    const url = `${API_BASE_URL}/${path}${qs}`;

    console.log(`[Proxy] ${method} ${url}`);

    // Get the request body for POST/PUT/PATCH requests
    let body = undefined;
    if (["POST", "PUT", "PATCH"].includes(method)) {
      try {
        body = await request.text();
        console.log(`[Proxy] Request body:`, body);
      } catch (error) {
        // If no body, that's fine
        console.log("error", error);
      }
    }

    // Forward the request to the actual API
    const response = await fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        // Forward any authorization headers
        ...(request.headers.get("authorization") && {
          Authorization: request.headers.get("authorization")!,
        }),
      },
      body,
    });

    console.log(`[Proxy] Response status: ${response.status}`);

    // Get the response data
    const data = await response.text();

    // Return the response with CORS headers
    return new NextResponse(data, {
      status: response.status,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods":
          "GET, POST, PUT, DELETE, PATCH, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  } catch (error) {
    console.error("[Proxy] Error:", error);
    const errorMessage = error instanceof Error ? error.message : "Proxy request failed";
    return NextResponse.json(
      {
        error: "Failed to connect to backend server",
        details: errorMessage,
        backend_url: API_BASE_URL
      },
      { status: 500 }
    );
  }
}

// Handle preflight requests
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, PATCH, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type, Authorization",
    },
  });
}
