# app.py
from flask import Flask, request, jsonify
import asyncio, os, sys
from concurrent.futures import ThreadPoolExecutor
import nest_asyncio
current_dir = os.path.dirname(os.path.abspath(__file__))
upper_level_dir = os.path.abspath(os.path.join(current_dir, '../../test_py'))
sys.path.append(upper_level_dir)
import scrape4_js as scrape  # Assuming scrape4_js.py contains your main function

nest_asyncio.apply()

app = Flask(__name__)
loop = asyncio.get_event_loop()
executor = ThreadPoolExecutor()
print(loop)

@app.route('/', methods=['POST'])
def main():

    async def run_scrape():
        return await scrape.main()

    future = executor.submit(asyncio.run, run_scrape())
    result = future.result()

    return jsonify({"video_url": result})

if __name__ == '__main__':
    app.run(debug=True, port=5000)