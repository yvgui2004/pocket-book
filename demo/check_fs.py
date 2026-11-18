"""检查大字号下原型页面是否溢出。"""
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).parent
URL = (HERE.parent / "记账App-完整原型.html").as_uri()
OUT = HERE / "check"


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome")
        page = browser.new_page(viewport={"width": 1180, "height": 900},
                                device_scale_factor=2)
        page.goto(URL)
        page.wait_for_timeout(500)
        page.evaluate("setFontScale(1.3)")
        page.wait_for_timeout(300)
        for pg in ("today", "bills"):
            page.locator(f"#lightRow .phone[data-page='{pg}']").screenshot(
                path=str(OUT / f"fs13_{pg}.png"))
        browser.close()
    print("done")


if __name__ == "__main__":
    main()