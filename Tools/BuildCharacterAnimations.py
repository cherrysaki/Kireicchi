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


def build(root, only=None):
    manifest = json.loads((root / "manifest.json").read_text())
    repo = root.parents[1]
    assets = repo / "Kireicchi/Assets.xcassets"
    previous_report = root / "validation.json"
    reports = []
    if only and previous_report.exists():
        reports = [r for r in json.loads(previous_report.read_text())["sheets"] if r["id"] not in only]
    galleries = [root / c["id"] for c in manifest["characters"]]
    for character in manifest["characters"]:
        identifier = character["id"]
        if only and identifier not in only:
            continue
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
        if character.get("outlineColor"):
            validate_blue_outline(output, character["outlineColor"])

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
    build_overview(root, manifest["characters"])


def validate_blue_outline(output, expected_color):
    expected = np.array([int(expected_color[i:i + 2], 16) for i in (1, 3, 5)])
    results = []
    for state in TIMINGS:
        for path in sorted((output / state).glob("*.png")):
            pixels = np.array(Image.open(path).convert("RGBA"))
            mask = pixels[:, :, 3] >= 128
            padded = np.pad(mask, 1)
            interior = (padded[:-2, 1:-1] & padded[2:, 1:-1] &
                        padded[1:-1, :-2] & padded[1:-1, 2:])
            edge = mask & ~interior
            rgb = pixels[:, :, :3].astype(int)
            blue = edge & (rgb[:, :, 2] > rgb[:, :, 0] + 35) & (rgb[:, :, 2] > rgb[:, :, 1] + 20)
            black = edge & (rgb.max(axis=2) < 55)
            fraction = float(blue.sum() / edge.sum())
            median = np.median(rgb[blue], axis=0)
            if fraction < .8 or black.sum() / edge.sum() > .02 or np.linalg.norm(median - expected) > 50:
                raise ValueError(f"{path}: body outline does not match the blue reference")
            results.append({"frame": path.relative_to(output).as_posix(),
                            "blue_outline_fraction": round(fraction, 3),
                            "black_outline_pixels": int(black.sum()),
                            "median_blue_rgb": median.astype(int).tolist()})
    (output / "outline-validation.json").write_text(json.dumps({
        "reference": "../references/character01.png", "expected_color": expected_color,
        "passed": True, "frames": results}, indent=2) + "\n")


def build_overview(root, characters):
    states = list(TIMINGS)
    contact = Image.new("RGB", (len(characters) * 200, len(states) * 178), "#FFF9EF")
    preview = [Image.new("RGB", (len(characters) * 200, 178), "#FFF9EF") for _ in range(28)]
    for column, character in enumerate(characters):
        identifier = character["id"]
        decoded = [Image.open(root / identifier / state / f"{i:02d}.png").convert("RGBA")
                   for state in states for i in range(4)]
        bounds = [f.getbbox() for f in decoded]
        common_box = (min(b[0] for b in bounds), min(b[1] for b in bounds),
                      max(b[2] for b in bounds), max(b[3] for b in bounds))
        factor = min(150 / (common_box[2] - common_box[0]), 140 / (common_box[3] - common_box[1]))
        for row, state in enumerate(states):
            static = Image.open(root / identifier / f"{identifier}_{state}.png").convert("RGBA")
            static = static.resize((150, 150), Image.Resampling.NEAREST)
            contact.paste(static, (column * 200 + 25, row * 178 + 22), static)
            ImageDraw.Draw(contact).text((column * 200 + 16, row * 178 + 4),
                                         f"{column + 1} {state}", fill="#4C3E3C")
            for index in range(4):
                image = decoded[row * 4 + index].crop(common_box)
                image = image.resize((round(image.width * factor), round(image.height * factor)),
                                     Image.Resampling.NEAREST)
                frame = preview[row * 4 + index]
                frame.paste(image, (column * 200 + (200 - image.width) // 2, 170 - image.height), image)
                ImageDraw.Draw(frame).text((column * 200 + 12, 5), f"{column + 1} {state}", fill="#4C3E3C")
    contact.save(root / "all-characters.png")
    preview[0].save(root / "all-characters.gif", save_all=True, append_images=preview[1:],
                    duration=260, loop=0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    parser.add_argument("--characters", nargs="+", help="Rebuild only these IDs; still validate all characters")
    args = parser.parse_args()
    build(args.root.resolve(), args.characters)
