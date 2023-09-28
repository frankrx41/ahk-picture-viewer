import ddddocr
import sys

from PIL import ImageGrab, Image
img = Image.open(sys.argv[1])

# dddd ocr
if img:
    ocr = ddddocr.DdddOcr(show_ad=False)
    res = ocr.classification(img)
    print(res, end="")
