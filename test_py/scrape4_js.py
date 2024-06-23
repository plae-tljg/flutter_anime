import asyncio
from pyppeteer import launch

async def main():
    # Launch the browser
    try:
        # browser = await launch(headless=True)
        browser = await launch(
            handleSIGINT=False,
            handleSIGTERM=False,
            handleSIGHUP=False
        )
    except Exception as e:
        print(f'An error occurred: {e}')
        print('position 1')
    
    try:
        page = await browser.newPage()
        await page.goto('https://anime1.me/23287')
        # Example: Using a simple CSS selector
        simple_css_selector_button = "#vjs-D1xfe"
        await page.waitForSelector(simple_css_selector_button, {'timeout': 60000})
        await page.click(simple_css_selector_button)
        await asyncio.sleep(10)  # Adjust the sleep time if necessary

        # Wait for the video source to be available and extract the URL
        simple_css_selector_video_source = "#vjs-D1xfe_html5_api"  # Replace with your actual CSS selector
        await page.waitForSelector(simple_css_selector_video_source)
        video_url = await page.evaluate(f'document.querySelector("{simple_css_selector_video_source}").src')
        print(f'Video URL: {video_url}\n')

        await browser.close()
        return video_url
    except Exception as e:
        print(f'An error occurred: {e}')
        print('position 2')
        return "An error occurred while scraping the video URL."

# To run the coroutine directly
if __name__ == "__main__":
    asyncio.run(main())