import json
import os
import unittest


class AlphaLanguageCanonTests(unittest.TestCase):
    def test_alpha_v1_language_order(self):
        root = os.path.dirname(os.path.dirname(__file__))
        path = os.path.join(root, "compliance", "alpha_v1_languages.json")
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)

        expected = [
            "Python",
            "C",
            "Java",
            "C++",
            "C#",
            "JavaScript",
            "Visual Basic",
            "R",
            "SQL",
            "Delphi/Object Pascal",
            "Fortran",
            "Scratch",
            "Perl",
            "PHP",
            "Rust",
            "Go",
            "Assembly language",
            "Swift",
            "Ada",
            "MATLAB",
            "Classic Visual Basic",
            "PL/SQL",
            "Ruby",
            "Prolog",
            "COBOL",
        ]

        self.assertEqual(data["scope"], "alpha_v1")
        self.assertEqual([item["order"] for item in data["languages"]], list(range(1, 26)))
        self.assertEqual([item["name"] for item in data["languages"]], expected)


if __name__ == "__main__":
    unittest.main()
