import requests

# Create a session object
session = requests.Session()

# Define the headers as specified
headers = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'en-US,en;q=0.5',
    'Connection': 'keep-alive',
    'DNT': '1',
    'Host': 'miru.v.anime1.me',
    'Priority': 'u=0, i',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Sec-GPC': '1',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0'
}

# Send a GET request to the specified URL with headers
url = 'https://miru.v.anime1.me/1502/3b.mp4'
response = session.get(url, headers=headers)

# Check if the request was successful
if response.status_code == 200:
    print("Successfully accessed the video file.")
    # Optionally, you can save the content to a file
    with open('3b.mp4', 'wb') as file:
        file.write(response.content)
else:
    print(f"Failed to access the video file: {response.status_code}")