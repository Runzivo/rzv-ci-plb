import unittest

from textstats import top_words, word_count


class WordCountTest(unittest.TestCase):
    def test_counts_words(self):
        self.assertEqual(word_count("one two  three"), 3)

    def test_empty_text(self):
        self.assertEqual(word_count(""), 0)

    def test_rejects_non_string(self):
        with self.assertRaises(TypeError):
            word_count(None)


class TopWordsTest(unittest.TestCase):
    def test_orders_by_count_then_word(self):
        text = "b a b c a b"
        self.assertEqual(top_words(text, 2), [("b", 3), ("a", 2)])

    def test_rejects_bad_limit(self):
        with self.assertRaises(ValueError):
            top_words("a", 0)


if __name__ == "__main__":
    unittest.main()
