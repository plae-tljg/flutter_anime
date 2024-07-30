import requests

# URL of the MP4 file
url = "https://muan.v.anime1.me/1500/4b.mp4"

# Headers to mimic the browser request
headers = {
    "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Sec-GPC": "1",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Priority": "u=0, i"
}

# Cookies from the browser
cookies = {
    "e": "1722271473",
    "p": "eyJpc3MiOiJhbmltZTEubWUiLCJleHAiOjE3MjIyNzE0NzMwMDAsImlhdCI6MTcyMjI0MjgxODAwMCwic3ViIjoiLzE1MDIvM2IubXA0In0",
    "h": "hljdBk741OW8xIBthiRZ0A",
    "_ga_1QW4P0C598": "GS1.1.1722235598.2.1.1722235916.60.0.0",
    "_ga": "GA1.1.794919538.1722228960"
}

response = requests.get(url, headers=headers, cookies=cookies, stream=True)

if response.status_code == 200:
    with open("4b.mp4", "wb") as file:
        for chunk in response.iter_content(chunk_size=1024):
            if chunk:
                file.write(chunk)
    print("Download completed successfully.")
else:
    print(f"Failed to download the file. Status code: {response.status_code}")