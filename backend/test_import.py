print("Testing Python imports...")
try:
    import fastapi
    print("✓ FastAPI imported")
    
    import uvicorn
    print("✓ uvicorn imported")
    
    import yfinance
    print("✓ yfinance imported")
    
    import pandas
    print("✓ pandas imported")
    
    print("\n✓ All imports successful!")
except Exception as e:
    print(f"✗ Import error: {e}")