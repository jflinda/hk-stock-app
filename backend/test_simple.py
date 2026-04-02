from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "Simple API test"}

@app.get("/test")
def test():
    return {"test": "success"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)