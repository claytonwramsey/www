"""
Script for converting HTML files with MathJax to HTML files with MML.

USAGE:
python mj2mml.py ./f.html
"""

import latex2mathml.converter
import re
import sys
import os

def convert(contents: str) -> str:
    # first, inline math
    splitout = re.split("\\\\\\(", contents)
    res = splitout[0]
    for snippet in splitout[1:]:
        snip_split = re.split("\\\\\\)", snippet)
        latex_eq = snip_split[0]
        remaining_text = snip_split[1]
        mml_eq = latex2mathml.converter.convert(latex_eq, xmlns="")
        print(f"{latex_eq} => {mml_eq}")
        res += mml_eq
        res += remaining_text
    # next, block math
    splitout = re.split("\\\\\\[", res)
    res = splitout[0]
    for snippet in splitout[1:]:
        snip_split = re.split("\\\\\\]", snippet)
        latex_eq = snip_split[0]
        remaining_text = snip_split[1]
        mml_eq = latex2mathml.converter.convert(latex_eq, xmlns="", display="block")
        print(f"{latex_eq} => {mml_eq}")
        res += mml_eq
        res += remaining_text
    return res

with open(sys.argv[1], "r+") as f:
    res = convert(f.read())
    f.seek(0)
    f.write(res)
    f.truncate()