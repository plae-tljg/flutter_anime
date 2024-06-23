import asyncio
from pyppeteer import launch

async def main():
    # Launch the browser
    browser = await launch(headless=True)
    page = await browser.newPage()

    # Open the target webpage
    await page.goto('https://anime1.me/23287')

    # Example: Using a simple CSS selector
    simple_css_selector_button = "#vjs-D1xfe"
    await page.waitForSelector(simple_css_selector_button,  {'timeout': 60000})
    await page.click(simple_css_selector_button)
    await asyncio.sleep(10)  # Adjust the sleep time if necessary

    # Wait for the video source to be available and extract the URL
    simple_css_selector_video_source = "#vjs-D1xfe_html5_api"  # Replace with your actual CSS selector
    await page.waitForSelector(simple_css_selector_video_source)
    
    video_url = await page.evaluate(f'document.querySelector("{simple_css_selector_video_source}").src')
    print(f'Video URL: {video_url}\n')
    print(video_url)

    # Close the browser
    await browser.close()
    print('\n1')
    print(video_url)

# Run the async function
asyncio.get_event_loop().run_until_complete(main())