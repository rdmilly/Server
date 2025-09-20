from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Dict, List, Any, Optional
import os
import json
import subprocess
import tempfile
import psycopg2
from minio import Minio
from datetime import datetime, timedelta
import httpx
from langfuse import Langfuse

# Initialize FastAPI app
app = FastAPI(
    title="Millyweb LangGraph API",
    description="Agent orchestration and tool calling backend",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Traefik handles security
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Environment configuration
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "localhost")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "chat")
POSTGRES_USER = os.getenv("POSTGRES_USER", "chat")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "password")

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minioadmin")

LANGFUSE_SECRET_KEY = os.getenv("LANGFUSE_SECRET_KEY")
LANGFUSE_PUBLIC_KEY = os.getenv("LANGFUSE_PUBLIC_KEY")
LANGFUSE_HOST = os.getenv("LANGFUSE_HOST", "https://logs.millyweb.com")

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")

# Initialize clients
minio_client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=False
)

langfuse = None
if LANGFUSE_SECRET_KEY and LANGFUSE_PUBLIC_KEY:
    langfuse = Langfuse(
        secret_key=LANGFUSE_SECRET_KEY,
        public_key=LANGFUSE_PUBLIC_KEY,
        host=LANGFUSE_HOST
    )

# Pydantic models
class ChatRequest(BaseModel):
    message: str
    model: str = "llama2"
    tool: Optional[str] = None
    context: Optional[Dict[str, Any]] = {}

class ChatResponse(BaseModel):
    response: str
    tool_calls: Optional[List[Dict[str, Any]]] = []
    trace_id: Optional[str] = None

class ToolRequest(BaseModel):
    command: str
    args: Optional[Dict[str, Any]] = {}

class ToolResponse(BaseModel):
    success: bool
    output: str
    error: Optional[str] = None

class FileRequest(BaseModel):
    path: str
    content: str
    mode: str = "w"

class PresignRequest(BaseModel):
    bucket: str
    object_name: str
    expiry: int = 3600  # 1 hour default

# Database connection
def get_db_connection():
    return psycopg2.connect(
        host=POSTGRES_HOST,
        port=POSTGRES_PORT,
        database=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD
    )

# Health check
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        conn = get_db_connection()
        conn.close()
        
        # Test MinIO connection
        minio_client.list_buckets()
        
        return {"ok": True, "timestamp": datetime.now().isoformat()}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

# Chat endpoint
@app.post("/run", response_model=ChatResponse)
async def run_chat(request: ChatRequest):
    """Main chat endpoint with optional tool switching"""
    trace_id = None
    
    try:
        # Create Langfuse trace if available
        if langfuse:
            trace = langfuse.trace(
                name="chat_completion",
                input={"message": request.message, "model": request.model}
            )
            trace_id = trace.id

        # Handle tool-specific logic
        if request.tool:
            tool_result = await handle_tool_call(request.tool, request.message, request.context)
            
            if langfuse and trace_id:
                langfuse.span(
                    trace_id=trace_id,
                    name=f"tool_{request.tool}",
                    input=request.context,
                    output=tool_result
                )
            
            return ChatResponse(
                response=f"Tool '{request.tool}' executed successfully",
                tool_calls=[tool_result],
                trace_id=trace_id
            )

        # Regular chat completion via Ollama
        async with httpx.AsyncClient() as client:
            ollama_response = await client.post(
                f"{OLLAMA_BASE_URL}/api/generate",
                json={
                    "model": request.model,
                    "prompt": request.message,
                    "stream": False
                },
                timeout=60.0
            )
            
            if ollama_response.status_code != 200:
                raise HTTPException(status_code=500, detail="Ollama request failed")
            
            result = ollama_response.json()
            response_text = result.get("response", "No response from model")

        # Store in database
        conn = get_db_connection()
        cur = conn.cursor()
        try:
            cur.execute(
                "INSERT INTO chat.messages (room_id, role, content, langfuse_trace_id) VALUES (1, 'user', %s, %s)",
                (request.message, trace_id)
            )
            cur.execute(
                "INSERT INTO chat.messages (room_id, role, content, langfuse_trace_id) VALUES (1, 'assistant', %s, %s)",
                (response_text, trace_id)
            )
            conn.commit()
        finally:
            cur.close()
            conn.close()

        # Update Langfuse trace
        if langfuse and trace_id:
            trace.update(output={"response": response_text})

        return ChatResponse(
            response=response_text,
            trace_id=trace_id
        )

    except Exception as e:
        if langfuse and trace_id:
            trace.update(output={"error": str(e)})
        raise HTTPException(status_code=500, detail=str(e))

# Tool handling
async def handle_tool_call(tool_name: str, message: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """Route tool calls to appropriate handlers"""
    
    if tool_name == "search_memory":
        return await search_memory_tool(message, context)
    elif tool_name == "get_file_url":
        return await get_file_url_tool(context)
    elif tool_name == "run_command":
        return await run_command_tool(context)
    elif tool_name == "write_file":
        return await write_file_tool(context)
    else:
        return {"success": False, "error": f"Unknown tool: {tool_name}"}

async def search_memory_tool(query: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """Search chat history and embeddings"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute(
            """
            SELECT content, role, created_at 
            FROM chat.messages 
            WHERE content ILIKE %s 
            ORDER BY created_at DESC 
            LIMIT 10
            """,
            (f"%{query}%",)
        )
        
        results = cur.fetchall()
        cur.close()
        conn.close()
        
        return {
            "success": True,
            "results": [
                {"content": row[0], "role": row[1], "timestamp": row[2].isoformat()}
                for row in results
            ]
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

async def get_file_url_tool(context: Dict[str, Any]) -> Dict[str, Any]:
    """Generate presigned URL for file access"""
    try:
        bucket = context.get("bucket", "documents")
        object_name = context.get("object_name")
        
        if not object_name:
            return {"success": False, "error": "object_name required"}
        
        url = minio_client.presigned_get_object(bucket, object_name, expires=timedelta(hours=1))
        
        return {
            "success": True,
            "url": url,
            "expires_in": 3600
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

async def run_command_tool(context: Dict[str, Any]) -> Dict[str, Any]:
    """Execute shell command in workspace"""
    try:
        command = context.get("command")
        if not command:
            return {"success": False, "error": "command required"}
        
        # Security: restrict to workspace directory
        result = subprocess.run(
            command,
            shell=True,
            cwd="/workspaces",
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "return_code": result.returncode
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

async def write_file_tool(context: Dict[str, Any]) -> Dict[str, Any]:
    """Write file to workspace"""
    try:
        path = context.get("path")
        content = context.get("content")
        
        if not path or content is None:
            return {"success": False, "error": "path and content required"}
        
        # Security: ensure path is within workspace
        full_path = os.path.join("/workspaces", path.lstrip("/"))
        if not full_path.startswith("/workspaces/"):
            return {"success": False, "error": "Path outside workspace not allowed"}
        
        # Create directory if needed
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
        with open(full_path, "w") as f:
            f.write(content)
        
        return {
            "success": True,
            "path": path,
            "size": len(content)
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

# Tools endpoint
@app.get("/tools")
async def get_tools():
    """Get available tool definitions"""
    return {
        "tools": [
            {
                "name": "search_memory",
                "description": "Search chat history and stored memories",
                "parameters": {
                    "query": {"type": "string", "description": "Search query"}
                }
            },
            {
                "name": "get_file_url",
                "description": "Generate presigned URL for file access",
                "parameters": {
                    "bucket": {"type": "string", "description": "Storage bucket"},
                    "object_name": {"type": "string", "description": "Object name/path"}
                }
            },
            {
                "name": "run_command",
                "description": "Execute shell command in workspace",
                "parameters": {
                    "command": {"type": "string", "description": "Shell command to execute"}
                }
            },
            {
                "name": "write_file",
                "description": "Write file to workspace",
                "parameters": {
                    "path": {"type": "string", "description": "File path"},
                    "content": {"type": "string", "description": "File content"}
                }
            }
        ]
    }

# Tool execution endpoints
@app.post("/tool/run_command", response_model=ToolResponse)
async def run_command_endpoint(request: ToolRequest):
    """Execute shell command"""
    result = await run_command_tool({"command": request.command})
    return ToolResponse(
        success=result["success"],
        output=result.get("stdout", ""),
        error=result.get("error") or result.get("stderr")
    )

@app.post("/tool/write_file", response_model=ToolResponse)
async def write_file_endpoint(request: FileRequest):
    """Write file to workspace"""
    result = await write_file_tool({
        "path": request.path,
        "content": request.content
    })
    return ToolResponse(
        success=result["success"],
        output=f"File written: {request.path}" if result["success"] else "",
        error=result.get("error")
    )

# Object storage presigned URLs
@app.get("/objects/presign/get")
async def presign_get_object(bucket: str, object_name: str, expiry: int = 3600):
    """Generate presigned GET URL"""
    try:
        url = minio_client.presigned_get_object(
            bucket, 
            object_name, 
            expires=timedelta(seconds=expiry)
        )
        return {"url": url, "expires_in": expiry}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/objects/presign/upload")
async def presign_upload_object(request: PresignRequest):
    """Generate presigned PUT URL for upload"""
    try:
        url = minio_client.presigned_put_object(
            request.bucket,
            request.object_name,
            expires=timedelta(seconds=request.expiry)
        )
        return {"url": url, "expires_in": request.expiry}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Langfuse traces endpoint (optional)
@app.get("/traces/latest")
async def get_latest_traces(limit: int = 5):
    """Get latest Langfuse traces (stub implementation)"""
    if not langfuse:
        return {"traces": [], "message": "Langfuse not configured"}
    
    try:
        # This is a stub - actual implementation would query Langfuse API
        return {
            "traces": [],
            "limit": limit,
            "message": "Langfuse integration active"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)