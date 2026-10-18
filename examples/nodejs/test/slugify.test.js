import assert from "node:assert/strict";
import { test } from "node:test";

import { slugify } from "../src/slugify.js";

test("joins words with hyphens", () => {
  assert.equal(slugify("Hello World"), "hello-world");
});

test("drops accents and punctuation", () => {
  assert.equal(slugify("  Café, déjà vu!  "), "cafe-deja-vu");
});

test("returns an empty string when nothing is left", () => {
  assert.equal(slugify("!!!"), "");
});

test("rejects non-string input", () => {
  assert.throws(() => slugify(42), TypeError);
});
