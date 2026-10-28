from __future__ import annotations

import json
from pathlib import Path
from typing import Any

MAX_PRODUCTS = 10
DATA_FILE = Path(__file__).resolve().parent.parent / "data" / "inventario_papeleria.json"


def is_valid_code(code: str) -> bool:
    if len(code) != 7:
        return False
    if code[3] != "-":
        return False
    if not code[:3].isalpha() or not code[:3].isupper():
        return False
    if not code[4:].isdigit():
        return False
    return True


def parse_money(value: str) -> int:
    if not value:
        return -1
    text = value.strip()
    if not text:
        return -1
    if any(ch not in "0123456789." for ch in text):
        return -1
    if text.count(".") > 1:
        return -1

    if "." in text:
        whole, frac = text.split(".", 1)
        if not whole and not frac:
            return -1
        if not whole:
            whole = "0"
        if len(frac) > 2:
            return -1
        if not frac:
            return -1
        if len(frac) == 1:
            frac += "0"
        if not whole.isdigit() or not frac.isdigit():
            return -1
        return int(whole) * 100 + int(frac)

    if not text.isdigit():
        return -1
    return int(text) * 100


def format_money(cents: int) -> str:
    sign = "-" if cents < 0 else ""
    cents = abs(cents)
    pesos, centavos = divmod(cents, 100)
    return f"{sign}${pesos}.{centavos:02d} MXN"


def normalize_name(name: str) -> str:
    cleaned = name.strip()
    if len(cleaned) < 1 or len(cleaned) > 25:
        raise ValueError("El nombre debe tener entre 1 y 25 caracteres.")
    return cleaned


def parse_quantity(value: str) -> int:
    if not value or not value.isdigit():
        raise ValueError("La cantidad debe ser un entero mayor que cero.")
    qty = int(value)
    if qty <= 0 or qty > 100:
        raise ValueError("La cantidad debe estar entre 1 y 100.")
    return qty


class InventorySystem:
    def __init__(self, file_path: Path | None = None):
        self.file_path = file_path or DATA_FILE
        self.products: list[dict[str, Any]] = []
        self.session_revenue = 0
        self.unsaved_changes = False
        self.load_from_disk()

    def _save_file_data(self) -> None:
        payload = {
            "products": self.products,
            "session_revenue": self.session_revenue,
        }
        self.file_path.parent.mkdir(parents=True, exist_ok=True)
        self.file_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
        self.unsaved_changes = False

    def load_from_disk(self) -> None:
        if not self.file_path.exists():
            self.products = [
                {"code": "ABC-123", "name": "Cuaderno profesional", "price_cents": 25000, "stock": 30},
                {"code": "DEF-456", "name": "Pluma azul", "price_cents": 18000, "stock": 50},
                {"code": "GHI-789", "name": "Resaltador amarillo", "price_cents": 12000, "stock": 25},
            ]
            self.session_revenue = 0
            return

        try:
            data = json.loads(self.file_path.read_text(encoding="utf-8"))
            products = data.get("products", [])
            validated: list[dict[str, Any]] = []
            for item in products:
                code = str(item.get("code", ""))
                name = str(item.get("name", ""))
                price = int(item.get("price_cents", 0))
                stock = int(item.get("stock", 0))
                if not is_valid_code(code):
                    raise ValueError("Codigo invalido en archivo.")
                if len(name) < 1 or len(name) > 25:
                    raise ValueError("Nombre invalido en archivo.")
                if not (1 <= price <= 999999):
                    raise ValueError("Precio invalido en archivo.")
                if not (0 <= stock <= 100):
                    raise ValueError("Existencia invalida en archivo.")
                validated.append({"code": code, "name": name, "price_cents": price, "stock": stock})
            self.products = validated
            self.session_revenue = int(data.get("session_revenue", 0))
        except (json.JSONDecodeError, TypeError, ValueError):
            self.products = [
                {"code": "ABC-123", "name": "Cuaderno profesional", "price_cents": 25000, "stock": 30},
                {"code": "DEF-456", "name": "Pluma azul", "price_cents": 18000, "stock": 50},
                {"code": "GHI-789", "name": "Resaltador amarillo", "price_cents": 12000, "stock": 25},
            ]
            self.session_revenue = 0
            print("Archivo invalido. Se usaron productos de demostración.")

    def save(self) -> None:
        self._save_file_data()
        print("Catalogo guardado correctamente.")

    def add_product(self, code: str, name: str, price_text: str, qty_text: str) -> str:
        if len(self.products) >= MAX_PRODUCTS:
            return "Capacidad máxima alcanzada (10 productos)."
        if not is_valid_code(code):
            return "Codigo invalido. Debe seguir el formato ABC-123."
        if any(item["code"] == code.upper() for item in self.products):
            return "Codigo duplicado. No se permite registrar el mismo producto."
        try:
            name = normalize_name(name)
            price_cents = parse_money(price_text)
            qty = parse_quantity(qty_text)
        except ValueError as exc:
            return str(exc)
        if price_cents < 1 or price_cents > 999999:
            return "Precio fuera de rango. Debe estar entre $0.01 y $9999.99 MXN."
        record = {"code": code.upper(), "name": name, "price_cents": price_cents, "stock": qty}
        self.products.append(record)
        self.unsaved_changes = True
        return "Producto registrado correctamente."

    def find_product(self, code: str) -> dict[str, Any] | None:
        for item in self.products:
            if item["code"] == code.upper():
                return item
        return None

    def receive_stock(self, code: str, qty_text: str) -> str:
        product = self.find_product(code)
        if product is None:
            return "Producto no encontrado."
        try:
            qty = parse_quantity(qty_text)
        except ValueError as exc:
            return str(exc)
        if product["stock"] + qty > 100:
            return "La recepción excede la capacidad máxima de 100 unidades."
        product["stock"] += qty
        self.unsaved_changes = True
        return "Mercancía recibida correctamente."

    def sell_product(self, code: str, qty_text: str) -> str:
        product = self.find_product(code)
        if product is None:
            return "Producto no encontrado."
        try:
            qty = parse_quantity(qty_text)
        except ValueError as exc:
            return str(exc)
        if qty > product["stock"]:
            return "No hay suficientes unidades para la venta."

        subtotal = product["price_cents"] * qty
        if qty >= 5:
            discount = subtotal * 10 // 100
            total = subtotal - discount
        else:
            discount = 0
            total = subtotal

        product["stock"] -= qty
        self.session_revenue += total
        self.unsaved_changes = True
        return (
            f"Venta aceptada. Importe base: {format_money(subtotal)}; "
            f"descuento: {format_money(discount)}; total: {format_money(total)}."
        )

    def show_inventory(self) -> str:
        if not self.products:
            return "No hay productos registrados."
        lines = ["Inventario actual:"]
        for item in self.products:
            lines.append(f"- {item['code']} | {item['name']} | {item['stock']} unidades | {format_money(item['price_cents'])}")
        return "\n".join(lines)

    def show_summary(self) -> str:
        total_units = sum(item["stock"] for item in self.products)
        inventory_value = sum(item["price_cents"] * item["stock"] for item in self.products)
        lines = [
            "Resumen general:",
            f"Unidades disponibles: {total_units}",
            f"Valor total del inventario: {format_money(inventory_value)}",
            f"Ingresos acumulados: {format_money(self.session_revenue)}",
            "Regla del negocio: descuento del 10% en compras de 5 o más unidades.",
        ]
        return "\n".join(lines)

    def exit_with_prompt(self) -> bool:
        if not self.unsaved_changes:
            return True
        answer = input("Hay cambios sin guardar. ¿Deseas guardarlos antes de salir? [s/N]: ").strip().lower()
        if answer in {"s", "si", "y", "yes"}:
            self.save()
            return True
        return True


def print_menu() -> None:
    print("\n=== PAPELERIA DEL VALLE ===")
    print("1) Registrar producto")
    print("2) Mostrar inventario")
    print("3) Buscar por código")
    print("4) Recibir mercancía")
    print("5) Vender producto")
    print("6) Mostrar resumen")
    print("7) Guardar catálogo")
    print("8) Cargar catálogo")
    print("9) Regla de negocio")
    print("0) Salir")


def main() -> None:
    system = InventorySystem(DATA_FILE)
    while True:
        print_menu()
        choice = input("Seleccione una opción: ").strip()

        if choice == "1":
            print("Código (ABC-123): ")
            code = input().strip()
            name = input("Nombre del producto: ").strip()
            price = input("Precio en MXN (ej. 185.50): ").strip()
            qty = input("Cantidad: ").strip()
            print(system.add_product(code, name, price, qty))
        elif choice == "2":
            print(system.show_inventory())
        elif choice == "3":
            code = input("Ingrese el código a buscar: ").strip()
            product = system.find_product(code)
            if product is None:
                print("Producto no encontrado.")
            else:
                print(f"Producto encontrado: {product['code']} | {product['name']} | {product['stock']} unidades | {format_money(product['price_cents'])}")
        elif choice == "4":
            code = input("Ingrese el código para recibir mercancia: ").strip()
            qty = input("Cantidad a recibir: ").strip()
            print(system.receive_stock(code, qty))
        elif choice == "5":
            code = input("Ingrese el código del producto a vender: ").strip()
            qty = input("Cantidad a vender: ").strip()
            print(system.sell_product(code, qty))
        elif choice == "6":
            print(system.show_summary())
        elif choice == "7":
            system.save()
        elif choice == "8":
            system.load_from_disk()
            print("Catálogo cargado correctamente.")
        elif choice == "9":
            print("Regla de negocio: descuento del 10% en compras de 5 o más unidades.")
        elif choice == "0":
            if system.exit_with_prompt():
                print("Gracias por usar la papelería.")
                break
        else:
            print("Entrada inválida. Intente nuevamente.")


if __name__ == "__main__":
    main()
