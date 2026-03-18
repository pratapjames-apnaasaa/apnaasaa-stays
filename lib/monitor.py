import os
from google import genai
from google.genai import types

# 1. Setup - Replace with your actual Gemini API Key
# Get your key at: https://aistudio.google.com/
GEMINI_API_KEY = "YOUR_GEMINI_API_KEY_HERE"

client = genai.Client(api_key=GEMINI_API_KEY)

def analyze_flutter_issue(error_log):
    print("\n[Agent] Analyzing Flutter Log...")
    
    prompt = f"""
    You are an Autonomous Flutter Debugger. 
    Analyze the following error log from a Flutter application.
    
    TASK:
    1. Identify if it is a 'Rendering/Layout' error or a 'Logic/Firebase' error.
    2. Provide the exact fix for the 'HostJourney' widget.
    3. Ensure the fix uses modern Dart syntax.

    ERROR LOG:
    {error_log}
    """

    try:
        response = client.models.generate_content(
            model='gemini-2.0-flash', # Or use 'gemini-3-flash'
            contents=prompt
        )
        print("\n--- AGENT DIAGNOSIS ---")
        print(response.text)
        print("-----------------------\n")
    except Exception as e:
        print(f"Agent Error: {e}")

if __name__ == "__main__":
    print("Agentic Monitor Active. Paste your Flutter error log below (Press Enter twice to analyze):")
    while True:
        lines = []
        while True:
            line = input()
            if line == "":
                break
            lines.append(line)
        
        user_log = "\n".join(lines)
        if user_log.strip():
            analyze_flutter_issue(user_log)