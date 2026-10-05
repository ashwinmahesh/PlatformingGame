#!/usr/bin/env python3
"""Download a public Google Drive folder (Quaternius packs) with the standard library.
Usage: gdrive_fetch.py <folder_id> <out_dir> [--only-ext .gltf,.glb,.bin,.png,.txt]"""
import html, os, re, sys, urllib.request

UA = {"User-Agent": "Mozilla/5.0"}
SKIP = {"blends", "blend", "fbx", "obj", "unity", "unreal", "source", "blender"}


def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60).read()


def listing(fid):
    page = get(f"https://drive.google.com/embeddedfolderview?id={fid}").decode("utf-8", "replace")
    items = []
    for m in re.finditer(r'href="https://drive.google.com/(file/d|drive/folders)/([A-Za-z0-9_-]+)[^"]*".*?flip-entry-title">([^<]*)<', page, re.S):
        items.append((m.group(1), m.group(2), html.unescape(m.group(3)).strip()))
    return items


def download(fid, path):
    data = get(f"https://drive.usercontent.google.com/download?id={fid}&export=download&confirm=t")
    with open(path, "wb") as f:
        f.write(data)


def walk(fid, out, exts, depth=0):
    os.makedirs(out, exist_ok=True)
    for kind, iid, name in listing(fid):
        target = os.path.join(out, name)
        if kind == "drive/folders":
            if name.lower() in SKIP:
                continue
            walk(iid, target, exts, depth + 1)
        elif not exts or os.path.splitext(name)[1].lower() in exts:
            if not os.path.exists(target):
                download(iid, target)
                print("  ", target, os.path.getsize(target))


if __name__ == "__main__":
    exts = []
    if "--only-ext" in sys.argv:
        exts = sys.argv[sys.argv.index("--only-ext") + 1].split(",")
    walk(sys.argv[1], sys.argv[2], exts)
