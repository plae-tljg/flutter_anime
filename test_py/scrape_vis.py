import requests
from bs4 import BeautifulSoup
from graphviz import Digraph

# url = 'https://anime1.me/'  # Replace with the actual URL you want to scrape
url = 'https://anime1.me/23287'
response = requests.get(url)
response.raise_for_status()  # Check for HTTP errors

soup = BeautifulSoup(response.content, 'html.parser')
print(soup.prettify()) 

def create_graph(soup, filename="dom_tree.gv"):
    dot = Digraph(comment='DOM Tree')
    dot.node('root', 'HTML')
    def traverse(node, parent_name):
        for child in node.children:
            if child.name:
                child_name = child.name
                dot.node(child_name, child_name)
                dot.edge(parent_name, child_name)
                traverse(child, child_name)
    traverse(soup, 'root')
    dot.render(filename, view=True)

filename = "dom_tree_" + url + ".gv"
create_graph(soup, filename)

# # This part depends heavily on the website's structure.
# # Inspect the HTML source (right-click on the page, "View Page Source")
# # to find the elements containing the anime names.
# # Example:
# # anime_elements = soup.find_all('div', class_='your-anime-class')  

# # anime_names = [anime.text.strip() for anime in anime_elements]

# # print(anime_names) 

# def build_tree(node):
#     children = node.find_all(recursive=False)
#     result = [(node.name, [build_tree(child) for child in children])]
#     return result

# html_tree = build_tree(soup.html)

# def add_nodes_edges(tree, parent_name, graph):
#     node_name = f"{id(tree)}"  # Unique identifier for the node
#     if parent_name:
#         graph.edge(parent_name, node_name)
#     label = tree[0] if isinstance(tree, tuple) else "html"
#     graph.node(node_name, label=label)
#     if isinstance(tree, tuple) and len(tree) > 1 and isinstance(tree[1], list):
#         for child in tree[1]:
#             add_nodes_edges(child, node_name, graph)

# dot = Digraph(comment='HTML Structure')
# add_nodes_edges(html_tree[0], None, dot)


# anime_elements = soup.find_all('div', class_='your-anime-class')  

# dot.render('output/html_tree', format='png', cleanup=True)
# print("Tree diagram generated and saved as 'html_tree.png'.")