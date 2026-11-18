"""验证原型交互：切到对角视图、翻月、选日。"""
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
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.goto(URL)
        page.wait_for_timeout(500)
        phone = page.locator("#lightRow .phone[data-page='bills']")
        phone.locator(".js-mode").click()
        page.wait_for_timeout(200)
        print("mode text:", phone.locator(".js-mode").inner_text())
        phone.screenshot(path=str(OUT / "interact_diag.png"))
        phone.locator(".js-mode").click()
        page.wait_for_timeout(150)
        print("mode text:", phone.locator(".js-mode").inner_text())
        phone.locator(".js-prev").click()
        page.wait_for_timeout(150)
        print("title:", phone.locator(".js-month-title").inner_text())
        print("errors:", errors)
        browser.close()


if __name__ == "__main__":
    main()