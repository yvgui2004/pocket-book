import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

HERE = Path(__file__).parent
URL = (HERE / "demo.html").as_uri()

SHOTS = [5.0, 19.6, 21.8]

def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        for layout, w, h in [("portrait", 1080, 1920), ("landscape", 1920, 1080)]:
            page = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
            page.goto(URL + f"?layout={layout}")
            page.wait_for_timeout(300)
            for t in SHOTS:
                page.evaluate("t => window.seek(t)", t)
                page.screenshot(path=str(HERE / f"preview_{layout}_{t:.1f}.png"))
            page.close()
        browser.close()
    print("done")

if __name__ == "__main__":
    main()