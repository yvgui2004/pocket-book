import shutil
import subprocess
import sys
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

HERE = Path(__file__).parent
URL = (HERE / "demo.html").as_uri()
FPS = 60


def render(layout, w, h, out_name):
    fdir = HERE / f"frames_{layout}"
    if fdir.exists():
        shutil.rmtree(fdir)
    fdir.mkdir()

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        page = browser.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
        page.goto(URL + f"?layout={layout}")
        page.wait_for_timeout(400)
        dur = page.evaluate("window.DURATION")
        total = int(dur * FPS)
        t0 = time.time()
        for i in range(total):
            page.evaluate("t => window.seek(t)", i / FPS)
            page.screenshot(path=str(fdir / f"{i:05d}.png"))
            if i % 300 == 0:
                print(f"{layout} {i}/{total} {time.time() - t0:.0f}s", flush=True)
        browser.close()

    subprocess.run(
        [
            "ffmpeg", "-y", "-loglevel", "error",
            "-framerate", str(FPS), "-i", str(fdir / "%05d.png"),
            "-c:v", "libx264", "-preset", "medium", "-crf", "16",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            str(HERE / out_name),
        ],
        check=True,
    )
    shutil.rmtree(fdir)
    print("done", out_name, flush=True)


if __name__ == "__main__":
    targets = sys.argv[1:] or ["portrait", "landscape"]
    if "portrait" in targets:
        render("portrait", 1080, 1920, "记账演示-竖屏.mp4")
    if "landscape" in targets:
        render("landscape", 1920, 1080, "记账演示-横屏.mp4")