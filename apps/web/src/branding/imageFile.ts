/** A chosen image file's pixel size, as the browser decodes it; rejects when it is not an image the browser can read. */
export function readImageSize(file: Blob): Promise<{ width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = () => {
      URL.revokeObjectURL(url);
      if (image.naturalWidth > 0 && image.naturalHeight > 0) resolve({ width: image.naturalWidth, height: image.naturalHeight });
      else reject(new Error('The image has no size.'));
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('The file could not be read as an image.'));
    };
    image.src = url;
  });
}
