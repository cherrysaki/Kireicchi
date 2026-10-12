"""Extract generated pose groups, register shared scales, and encode app assets.

Run with the bundled Python runtime (Pillow and NumPy):
  python3 Tools/BuildCharacterAnimations.py DesignAssets/CleaningCharacters
The input manifest records the generated sheets and identity references.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

STATES = {"moods": ["normal", "happy", "sad", "sick"],
          "actions": ["walk", "cheer", "run"]}
TIMINGS = {"normal": [420, 120, 120, 420], "happy": [280, 180, 220, 280],
           "sad": [500, 280, 220, 500], "sick": [480, 240, 180, 480],
           "walk": [150] * 4, "cheer": [200] * 4, "run": [100] * 4}


def connected_regions(mask):
    """Label connected opaque pixel runs; never assume equal source slots."""
    parent, runs, previous = [], [], []

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for y, row in enumerate(mask):
        changes = np.diff(np.pad(row.astype(np.int8), (1, 1)))
        starts, ends = np.where(changes == 1)[0], np.where(changes == -1)[0]
        current = []
        p = 0
        for left, right in zip(starts, ends):
            label = len(parent)
            parent.append(label)
            while p < len(previous) and previous[p][1] < left:
                p += 1
            q = p
            while q < len(previous) and previous[q][0] <= right:
                a, b = root(label), root(previous[q][2])
                parent[a] = b
                q += 1
            current.append((int(left), int(right), label))
            runs.append((y, int(left), int(right), label))
        previous = current

    labels = np.full(mask.shape, -1, dtype=np.int32)
    regions = {}
    for y, left, right, label in runs:
        key = root(label)
        labels[y, left:right] = key
        if key not in regions:
            regions[key] = {"key": key, "area": 0, "bbox": [left, y, right, y + 1]}
        region = regions[key]
        region["area"] += right - left
        box = region["bbox"]
        region["bbox"] = [min(box[0], left), min(box[1], y),
                          max(box[2], right), max(box[3], y + 1)]
    return labels, list(regions.values())


def extract_sheet(path, row_count):
    image = Image.open(path).convert("RGBA")
    rgba = np.array(image)
    labels, regions = connected_regions(rgba[:, :, 3] >= 128)
    largest = max(r["area"] for r in regions)
    seeds = [r for r in regions if r["area"] >= largest * .45]
    if len(seeds) != row_count * 4:
        raise ValueError(f"{path}: expected {row_count * 4} complete poses, found {len(seeds)}")
    seeds.sort(key=lambda r: (r["bbox"][1] + r["bbox"][3]) / 2)
    ordered = []
    for row in range(row_count):
        ordered.extend(sorted(seeds[row * 4:row * 4 + 4], key=lambda r: r["bbox"][0]))
    groups = [{r["key"]} for r in ordered]
    seed_keys = {r["key"] for r in seeds}
    for r in regions:
        if r["key"] in seed_keys or r["area"] < largest * .012:
            continue
        cx, cy = (r["bbox"][0] + r["bbox"][2]) / 2, (r["bbox"][1] + r["bbox"][3]) / 2
        nearest = min(range(len(ordered)), key=lambda i:
                      ((ordered[i]["bbox"][0] + ordered[i]["bbox"][2]) / 2 - cx) ** 2 +
                      ((ordered[i]["bbox"][1] + ordered[i]["bbox"][3]) / 2 - cy) ** 2)
        groups[nearest].add(r["key"])

    frames, boxes = [], []
    for group in groups:
        mask = np.isin(labels, list(group))
        ys, xs = np.where(mask)
        box = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
        if box[0] == 0 or box[1] == 0 or box[2] == image.width or box[3] == image.height:
            raise ValueError(f"{path}: clipped pose {box}")
        x0, y0, x1, y1 = box
        pixels = rgba[y0:y1, x0:x1].copy()
        selected = mask[y0:y1, x0:x1]
        pixels[~selected] = 0
        pixels[selected, 3] = 255
        frames.append(Image.fromarray(pixels))
        boxes.append(box)
    # One common scale for every pose in this source sheet.
    scale = 340 / float(np.median([b[3] - b[1] for b in boxes[:4]]))
    return frames, boxes, scale


def registered(frame, scale, size=(800, 450), offset=0, flip=False):
    sprite = frame.resize((round(frame.width * scale), round(frame.height * scale)), Image.Resampling.NEAREST)
    if flip:
        sprite = sprite.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    baseline = round(size[1] * .9)
    x, y = (size[0] - sprite.width) // 2 + offset, baseline - sprite.height
    if x < 4 or y < 4 or x + sprite.width > size[0] - 4:
        raise ValueError("Registered sprite would clip")
    canvas = Image.new("RGBA", size)
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def save_gif(frames, durations, path):
    # GIF has binary alpha; reserve palette index 255 for transparent pixels.
    rgb_frames = []
    for frame in frames:
        rgb = Image.new("RGB", frame.size, "#FFF9EF")
        rgb.paste(frame, mask=frame.getchannel("A"))
        rgb_frames.append(rgb)
    sheet = Image.new("RGB", (frames[0].width, frames[0].height * len(frames)))
    for i, frame in enumerate(rgb_frames):
        sheet.paste(frame, (0, i * frame.height))
    palette = sheet.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    encoded = []
    for rgb, rgba in zip(rgb_frames, frames):
        result = rgb.quantize(palette=palette, dither=Image.Dither.NONE)
        result.paste(255, mask=rgba.getchannel("A").point(lambda a: 255 if a < 128 else 0))
        result.info["transparency"] = 255
        encoded.append(result)
    encoded[0].save(path, save_all=True, append_images=encoded[1:], duration=durations,
                    loop=0, transparency=255, disposal=2, optimize=False)


def asset_file(root, name, suffix, payload, kind):
    folder = root / f"{name}.{kind}"
    folder.mkdir(parents=True, exist_ok=True)
    filename = name + suffix
    (folder / filename).write_bytes(payload)
    content = {"info": {"author": "xcode", "version": 1}}
    if kind == "dataset":
        content["data"] = [{"filename": filename, "idiom": "universal"}]
    else:
        content["images"] = [{"filename": filename, "idiom": "universal"}]
    (folder / "Contents.json").write_text(json.dumps(content, indent=2) + "\n")


def build(root):
    manifest = json.loads((root / "manifest.json").read_text())
    repo = root.parents[1]
    assets = repo / "Kireicchi/Assets.xcassets"
    reports, galleries = [], []
    for character in manifest["characters"]:
        identifier = character["id"]
        output = root / identifier
        output.mkdir(exist_ok=True)
        all_frames = []
        for kind, states in STATES.items():
            frames, boxes, scale = extract_sheet(root / character[kind], len(states))
            portrait_scale = min(scale * 400 / 340, 460 / max(f.width for f in frames))
            reports.append({"id": identifier, "sheet": kind, "source_boxes": boxes,
                            "common_scale": scale, "pose_count": len(frames)})
            for row, state in enumerate(states):
                poses = frames[row * 4:row * 4 + 4]
                registered_frames = [registered(f, scale) for f in poses]
                frame_dir = output / state
                frame_dir.mkdir(exist_ok=True)
                for i, frame in enumerate(registered_frames):
                    frame.save(frame_dir / f"{i:02d}.png")
                image_path = output / f"{identifier}_{state}.png"
                registered(poses[0], portrait_scale, (512, 512)).save(image_path)
                gif_path = output / f"{identifier}_{state}.gif"
                animation, durations = registered_frames, TIMINGS[state]
                if state == "walk":
                    # Traverse and return with generated alternating foot/arm poses.
                    offsets = np.linspace(-100, 100, 12).round().astype(int).tolist()
                    animation = [registered(poses[i % 4], scale, offset=x) for i, x in enumerate(offsets)]
                    animation += [registered(poses[i % 4], scale, offset=x, flip=True)
                                  for i, x in enumerate(reversed(offsets))]
                    durations = [150] * len(animation)
                save_gif(animation, durations, gif_path)
                asset_file(assets / identifier, identifier + "_" + state, ".gif", gif_path.read_bytes(), "dataset")
                asset_file(assets, identifier + "_" + state + "_static", ".png", image_path.read_bytes(), "imageset")
                all_frames.extend(registered_frames)
                if state == "happy":
                    portrait = output / f"{identifier}_portrait.gif"
                    save_gif([registered(f, portrait_scale, (512, 512)) for f in poses], TIMINGS[state], portrait)
                    asset_file(assets / identifier, identifier + "_portrait", ".gif", portrait.read_bytes(), "dataset")
        save_gif(all_frames, [200] * len(all_frames), output / "all-states.gif")
        contact = Image.new("RGB", (4 * 192, 7 * 130), "#FFF9EF")
        for i, frame in enumerate(all_frames):
            small = frame.resize((192, 108), Image.Resampling.NEAREST)
            contact.paste(small, ((i % 4) * 192, (i // 4) * 130 + 20), small)
            if i % 4 == 0:
                ImageDraw.Draw(contact).text((6, (i // 4) * 130 + 4), list(TIMINGS)[i // 4], fill="#4C3E3C")
        contact.save(output / "contact-sheet.png")
        galleries.append(output)

    # Validate all delivered static images and encoded GIFs, not just source geometry.
    validation = []
    for output in galleries:
        for state in TIMINGS:
            path = output / f"{output.name}_{state}.gif"
            image = Image.open(path)
            hashes = []
            for i in range(image.n_frames):
                image.seek(i)
                frame = image.convert("RGBA")
                if frame.getpixel((0, 0))[3] != 0 or not frame.getbbox():
                    raise ValueError(f"{path}: background or missing frame")
                hashes.append(hashlib.sha256(frame.tobytes()).hexdigest())
            if len(set(hashes)) < 3:
                raise ValueError(f"{path}: fewer than three unique animation frames")
            validation.append({"asset": path.relative_to(root).as_posix(), "frames": image.n_frames,
                               "unique_frames": len(set(hashes)), "transparent": True})
    (root / "validation.json").write_text(json.dumps({"sheets": reports, "animations": validation,
                                                       "passed": True}, indent=2) + "\n")
    print(f"Built and validated {len(validation)} state animations for {len(galleries)} characters")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    build(parser.parse_args().root.resolve())
