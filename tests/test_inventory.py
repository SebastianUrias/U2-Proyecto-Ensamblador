import unittest
from pathlib import Path
import tempfile

from src.papeleria import InventorySystem, is_valid_code, parse_money


class InventorySystemTests(unittest.TestCase):
    def test_code_validation(self):
        self.assertTrue(is_valid_code("ABC-123"))
        self.assertFalse(is_valid_code("abc-123"))
        self.assertFalse(is_valid_code("AB-12"))

    def test_parse_money(self):
        self.assertEqual(parse_money("185.50"), 18550)
        self.assertEqual(parse_money("12.05"), 1205)
        self.assertEqual(parse_money("250"), 25000)
        self.assertEqual(parse_money("0.01"), 1)
        self.assertEqual(parse_money("abc"), -1)
        self.assertEqual(parse_money("1."), -1)

    def test_add_product(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "catalog.json"
            system = InventorySystem(path)
            msg = system.add_product("XYZ-999", "Goma de borrar", "12.50", "8")
            self.assertIn("Producto registrado", msg)
            self.assertEqual(len(system.products), 4)
            self.assertEqual(system.find_product("XYZ-999")["stock"], 8)

    def test_duplicate_product_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "catalog.json"
            system = InventorySystem(path)
            system.add_product("XYZ-999", "Goma", "12.50", "8")
            msg = system.add_product("XYZ-999", "Otra goma", "15.00", "4")
            self.assertIn("duplicado", msg.lower())

    def test_sale_with_discount(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "catalog.json"
            system = InventorySystem(path)
            system.products = [{"code": "ABC-123", "name": "Cuaderno", "price_cents": 1000, "stock": 5}]
            msg = system.sell_product("ABC-123", "5")
            self.assertIn("descuento", msg.lower())
            self.assertEqual(system.products[0]["stock"], 0)
            self.assertEqual(system.session_revenue, 4500)

    def test_save_and_load_round_trip(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "catalog.json"
            system = InventorySystem(path)
            system.products = [{"code": "ABC-123", "name": "Cuaderno", "price_cents": 25000, "stock": 10}]
            system.save()
            loaded = InventorySystem(path)
            self.assertEqual(loaded.products[0]["code"], "ABC-123")
            self.assertEqual(loaded.products[0]["stock"], 10)


if __name__ == "__main__":
    unittest.main()
