<<<<<<< HEAD
# MVP Backend for Forecasting

## Overview

This repository contains two components:
- `ui/`: A Streamlit-based user interface for visualizing forecasts.
- `api/`: A FastAPI-based backend exposing forecasting endpoints.

## Quickstart

### Running the UI
Navigate to the `ui/` directory and install dependencies:
```bash
cd ui
pip install -r requirements.txt
```

Run the Streamlit application:
```bash
streamlit run app.py
```

### Running the API
Navigate to the `api/` directory and install dependencies:
```bash
cd api
pip install -r requirements.txt
```

Run the FastAPI application:
```bash
uvicorn main:app --reload
```

### Documentation
See the `docs/` folder for the MVP scope and UX copy.

## Environment Variables
Set your `.env` file with the following:
```
FMP_API_KEY=your_actual_api_key_here
```
=======
>>>>>>> main
