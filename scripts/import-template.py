"""Rebuild the selected design from the user's original SVG files."""
from pathlib import Path
from copy import deepcopy
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
sources, dest = root / "assets/source-icons", root / "assets/approved"
NS = "{http://www.w3.org/2000/svg}"
ET.register_namespace("", NS[1:-1])

def load(name):
    svg = ET.parse(sources / name).getroot()
    for parent in list(svg.iter()):
        for child in list(parent):
            if child.tag == NS + "style":
                parent.remove(child)
    for node in svg.iter():
        if node.attrib.pop("class", None) == "st0":
            node.set("fill", "currentColor")
        for key in ("fill", "stroke"):
            if node.get(key) in ("#000000", "#000", "black"):
                node.set(key, "currentColor")
    svg.attrib = {k: v for k, v in svg.attrib.items() if k in ("viewBox", "fill")}
    return svg

def save(name, svg):
    (dest / (name + ".svg")).write_text(ET.tostring(svg, encoding="unicode") + "\n")

# The selected screenshot reverses the pair from the previous proposal:
# L has its head down and stem up/right; R has its head up and stem down/left.
save("bud-left", load("blade-head-down.svg"))
save("bud-right", load("blade-head-up.svg"))
shield = load("shield-alt-1-svgrepo-com.svg")
ear = load("ear-2-svgrepo-com.svg")
ear.set("viewBox", "100 -8 312 530")
ear.set("x", "7.4")
ear.set("y", "5.1")
ear.set("width", "9.2")
ear.set("height", "14.3")
shield.append(ear)
save("mode-anc", shield)
save("mode-ambient", load("ear-3-svgrepo-com.svg"))
save("mode-normal", load("power-off-svgrepo-com.svg"))
