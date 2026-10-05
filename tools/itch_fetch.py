#!/usr/bin/env python3
"""Download the files of a free itch.io asset pack (the "No thanks, just take me to the
downloads" path), standard library only. Usage: itch_fetch.py <page_url> <out_dir> [name_filter]"""
import http.cookiejar, json, os, re, sys, urllib.parse, urllib.request

jar = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
opener.addheaders = [("User-Agent", "Mozilla/5.0")]


def get(url, data=None, headers=None):
    req = urllib.request.Request(url, data=data, headers=headers or {})
    return opener.open(req, timeout=120).read()


def main(page, out, flt=""):
    html = get(page).decode("utf-8", "replace")
    csrf = re.search(r'name="csrf_token" value="([^"]+)"', html) or re.search(r'csrf_token["\']?\s*[:=]\s*["\']([^"\']+)', html)
    data = urllib.parse.urlencode({"csrf_token": csrf.group(1) if csrf else ""}).encode()
    info = json.loads(get(page.rstrip("/") + "/download_url", data, {"X-Requested-With": "XMLHttpRequest"}))
    dl = info["url"]
    page2 = get(dl).decode("utf-8", "replace")
    key = urllib.parse.unquote(dl.rstrip("/").split("/")[-1])
    csrf2 = re.search(r'name="csrf_token" value="([^"]+)"', page2)
    os.makedirs(out, exist_ok=True)
    for m in re.finditer(r'data-upload_id="(\d+)".*?title="([^"]+)" class="name"', page2, re.S):
        uid, name = m.group(1), m.group(2)
        print("upload", uid, name)
        if flt and flt.lower() not in name.lower():
            continue
        d = urllib.parse.urlencode({"csrf_token": csrf.group(1) if csrf else ""}).encode()
        j = json.loads(get(page.rstrip("/") + f"/file/{uid}?source=view_game&as_props=1&after_download_lightbox=true", d, {"X-Requested-With": "XMLHttpRequest"}))
        target = os.path.join(out, name)
        with open(target, "wb") as f:
            f.write(get(j["url"]))
        print("  saved", target, os.path.getsize(target))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "")
