import os
import json
import glob
import re
from pathlib import Path
from datetime import datetime, timezone
from dotenv import load_dotenv
from google import genai

# Load environment variables
load_dotenv(override=True)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

def _load_transcript(ticker: str) -> str:
    """Smart Loader: Finds the first .txt file with the ticker name in /transcripts."""
    base = Path(__file__).resolve().parent
    transcript_dir = base / "transcripts"
    
    search_pattern = str(transcript_dir / f"*{ticker}*.txt")
    files = glob.glob(search_pattern)
    
    if not files:
        return ""
    
    newest_file = max(files, key=os.path.getctime)
    try:
        with open(newest_file, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception as e:
        print(f"Error reading transcript: {e}")
        return ""

def call_gemini_analysis(transcript_text: str, ticker: str) -> dict:
    """Call Gemini API to analyze the earnings transcript."""
    if not GEMINI_API_KEY:
        return {"error": "Missing GEMINI_API_KEY"}

    try:
        client = genai.Client(api_key=GEMINI_API_KEY)
        model_name = "gemini-1.5-flash"
        
        prompt = f"""
        You are a financial analyst extracting key insights from an earnings call transcript for {ticker}.
        
        TASK: Extract EXACTLY:
        - 2 most important TAILWINDS (positive growth drivers mentioned by management)
        - 1 most important HEADWIND (main risk or challenge mentioned by management) 
        - 1 PRIMARY ATTRIBUTION (main reason given for overall performance)
        
        CRITICAL RULES:
        1. Focus on statements made by COMPANY EXECUTIVES (CEO, CFO, etc.)
        2. For each item, provide a "claim" that summarizes it in 1 sentence
        3. For each item, provide a "quote" that is the EXACT, VERBATIM text from the transcript
        4. Quotes should be 1-2 sentences MAXIMUM - extract only the most relevant part
        5. Prioritize quotes that contain NUMBERS or SPECIFIC METRICS (%, $ amounts, growth rates)
        6. If no clear quote exists, use "Specific quote not found in transcript"
        
        DESIRED JSON FORMAT:
        {{
          "tailwinds": [
            {{"claim": "Clear summary of first tailwind", "quote": "Exact quote with numbers if possible"}},
            {{"claim": "Clear summary of second tailwind", "quote": "Exact quote with numbers if possible"}}
          ],
          "headwind": {{"claim": "Clear summary of main headwind", "quote": "Exact quote with numbers if possible"}},
          "attribution": {{"claim": "Clear summary of primary performance driver", "quote": "Exact quote with numbers if possible"}}
        }}
        
        TRANSCRIPT EXCERPT:
        {transcript_text[:30000]}
        """
        
        print(f"Calling Gemini API with model: {model_name}")
        response = client.models.generate_content(
            model=model_name,
            contents=prompt
        )
        
        text = response.text.strip()
        text = re.sub(r'```json\s*|\s*```', '', text)
        
        try:
            result = json.loads(text)
            print(f"DEBUG: Parsed JSON successfully")
            return result
        except json.JSONDecodeError:
            json_match = re.search(r'\{.*\}', text, re.DOTALL)
            if json_match:
                result = json.loads(json_match.group())
                print(f"DEBUG: Extracted JSON from response")
                return result
            else:
                return {"error": f"Could not parse JSON from response"}
                
    except Exception as e:
        print(f"DEBUG: Gemini API exception: {type(e).__name__}: {str(e)}")
        return {"error": f"Gemini API call failed: {type(e).__name__}: {str(e)}"}

def get_fallback_data(ticker: str) -> dict:
    """Return fallback mock data if Gemini fails."""
    # Simplified fallback structure
    return {
        "tailwinds": [
            {"claim": "Strong AI demand (Fallback)", "quote": "Demand remains exceptional."},
            {"claim": "Operational efficiency (Fallback)", "quote": "Margins improved significantly."}
        ],
        "headwind": {"claim": "Supply constraints (Fallback)", "quote": "We remain supply constrained."},
        "attribution": {"claim": "Execution (Fallback)", "quote": "Solid execution drove results."}
    }

def get_why_data(ticker: str) -> dict:
    """Main function to get 'why' data from transcripts."""
    print(f"\n=== Processing {ticker} ===")
    
    transcript = _load_transcript(ticker)
    
    # Helper to format return object
    def format_response(data, source, unknowns=None):
        # NORMALIZATION STEP: Wrap single headwind in a list
        hw = data.get("headwind", {})
        headwinds_list = [hw] if hw and "claim" in hw else []
        
        return {
            "ticker": ticker,
            "period": "Latest Quarter", 
            "as_of": datetime.now(timezone.utc).isoformat(),
            "tailwinds": data.get("tailwinds", []),
            "headwinds": headwinds_list, # <--- CRITICAL FIX: PLURAL LIST
            "attribution": data.get("attribution", {}),
            "unknowns": unknowns or [],
            "source": source
        }

    # 1. Check Transcript
    if not transcript:
        print(f"Warning: No transcript found for {ticker}")
        return format_response(get_fallback_data(ticker), "Fallback data (no transcript)", ["No transcript file found"])
    
    # 2. Check API Key
    if not GEMINI_API_KEY:
        print("Warning: GEMINI_API_KEY not set")
        return format_response(get_fallback_data(ticker), "Fallback data (no API key)", ["GEMINI_API_KEY not set"])
    
    # 3. Call Gemini
    try:
        print(f"Calling Gemini API for analysis...")
        analysis = call_gemini_analysis(transcript, ticker)
        
        if "error" in analysis:
            print(f"Gemini API error: {analysis['error']}")
            return format_response(get_fallback_data(ticker), "Fallback data (API error)", [f"Gemini API failed: {analysis['error']}"])
        
        print(f"Successfully analyzed transcript with Gemini")
        return format_response(analysis, "Gemini 2.0 Flash Analysis")
        
    except Exception as e:
        print(f"Unexpected error: {type(e).__name__}: {str(e)}")
        return format_response(get_fallback_data(ticker), "Fallback data (unexpected error)", [f"Unexpected error: {str(e)}"])