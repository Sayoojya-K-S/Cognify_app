from google import genai

client = genai.Client(api_key="AIzaSyA84_RX23oujcRfb2t6F_TN9vfp0mIPiz4")

response = client.models.generate_content(
    model="gemini-2.0-flash",
    contents="Say hello"
)

print(response.text)