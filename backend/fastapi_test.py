"""
测试 FastAPI 功能
"""
from fastapi import FastAPI

# 创建一个简单的 FastAPI 应用
app = FastAPI()

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "FastAPI test successful"}

if __name__ == "__main__":
    import uvicorn
    print("Starting FastAPI test server on port 8001...")
    uvicorn.run(app, host="0.0.0.0", port=8001)