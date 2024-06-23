import requests
from bs4 import BeautifulSoup

# Sample HTML snippet
html_snippet = """
<tr class="odd"><td><a href="//anime1.me/?cat=1453">RINKAI！女子競輪</a></td><td>連載中(11)</td><td>2024</td><td>春</td><td></td></tr>
"""

soup = BeautifulSoup(html_snippet, 'html.parser')

# Find the table row (<tr>) element with class "odd"
rows = soup.find_all('tr', class_='odd')

# Extract data from the table row elements
with open("extracted_text.txt", "w") as f:
    for row in rows:
        anime_name = row.find('a').text.strip()
        episodes = row.find_all('td')[1].text.strip()
        year = row.find_all('td')[2].text.strip()
        season = row.find_all('td')[3].text.strip()
        subtitle_group = row.find_all('td')[4].text.strip()

        # Create a dictionary to store the anime data
        anime_data = {
            'name': anime_name,
            'episodes': episodes,
            'year': year,
            'season': season,
            'subtitle_group': subtitle_group
        }

        # Print the extracted anime data
        print(anime_data)