#!/usr/bin/env python
import uvicorn
import sys
import os

if __name__ == "__main__":
    # 切换到backend目录
    os.chdir(os.path.join(os.path.dirname(__file__), "backend"))
    
    # 启动服务器
    print("Starting HK Stock API Server on port 8001...")
    print("Local: http://localhost:8001")
    print("Mobile: http://192.168.3.30:8001")
    print("Docs: http://localhost:8001/docs")
    print("ReDoc: http://localhost:8001/redoc")
    print("Ping: http://localhost:8001/ping")
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=False,
        log_level="info"
    )