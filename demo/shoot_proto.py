"""截取原型页面里的手机框架图，方便检查排版。"""
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).parent
URL = (HERE.parent / "记账App-完整原型.html").as_uri()
OUT = HERE / "check"
OUT.mkdir(exist_ok=True)


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome")
        page = browser.new_page(viewport={"width": 1180, "height": 900},
                                device_scale_factor=2)
        page.goto(URL)
        page.wait_for_timeout(600)
        for row in ("lightRow", "darkRow"):
            for pg in ("today", "bills", "settings"):
                el = page.locator(f"#{row} .phone[data-page='{pg}']")
                el.screenshot(path=str(OUT / f"{row}_{pg}.png"))
        browser.close()
    print("done")


if __name__ == "__main__":
    main()