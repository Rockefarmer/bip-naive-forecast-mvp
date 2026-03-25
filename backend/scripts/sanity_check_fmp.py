# Placeholder script to verify connection to Financial Modeling Prep API

import os
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
FMP_API_KEY = os.getenv("FMP_API_KEY")

def sanity_check():
    if not FMP_API_KEY:
        print("Error: FMP_API_KEY is not set in the .env file.")
        return

    url = f"https://financialmodelingprep.com/api/v3/profile/AAPL?apikey={FMP_API_KEY}"
    response = requests.get(url)

    if response.status_code == 200:
        print("FMP API request successful!")
        print(response.json())
    else:
        print(f"FMP API request failed with status code {response.status_code}")

if __name__ == "__main__":
    sanity_check()