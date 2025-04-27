import requests
from bs4 import BeautifulSoup
from graphviz import Digraph

url = 'https://anime1.me/'  # Replace with the actual URL you want to scrape
response = requests.get(url)
response.raise_for_status()  # Check for HTTP errors
print(response)
soup = BeautifulSoup(response.content, 'html.parser')
with open("html.txt", "w") as g:
    g.write(soup.prettify())
# print(soup)

# print(soup.prettify()[:1000])  # Print the first 1000 characters of the parsed HTML
odd_rows = soup.find_all('ul')[1]
odd_rows1 = odd_rows.find_all('li')

# Write to file (if you want to save all the texts)
with open("extracted_text.txt", "w") as f:
    for row in odd_rows:
        anime_name = row.find('a').text.strip()
        url = row.find('a')['href']

        # Create a dictionary to store the anime data
        anime_data = {
            'name': anime_name,
            'url': url
        }

        if anime_name:
            print(anime_data)
            f.write(str(anime_data))
            f.write('\n')