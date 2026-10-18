// Convert a title to a URL slug: lowercase ASCII words joined by hyphens.
export function slugify(title) {
  if (typeof title !== "string") {
    throw new TypeError("title must be a string");
  }
  return title
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
