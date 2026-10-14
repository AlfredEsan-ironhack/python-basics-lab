# Q16 - Debugging
# Answer: C - convert price to float before multiplying
price = "12.50"
total = float(price) * 2
print(total)  # 25.0


# Q17 - Build a Small Order Calculator
order_id = input("Order ID: ")
city = input("City: ")
unit_price = float(input("Unit price: "))        # decimal -> float
quantity = int(input("Quantity: "))              # whole number -> int
discount_percent = float(input("Discount %: "))

subtotal = unit_price * quantity
discount_amount = subtotal * discount_percent / 100
final_total = subtotal - discount_amount

print(
    f"Order {order_id} ({city}): "
    f"subtotal £{subtotal:.2f} | "
    f"discount £{discount_amount:.2f} | "
    f"final total £{final_total:.2f}"
)


# Q18 - Create Validation Flags (extends Q17)
valid_quantity = quantity > 0
valid_discount = 0 <= discount_percent <= 100
all_valid = valid_quantity and valid_discount

print("valid_quantity:", valid_quantity)
print("valid_discount:", valid_discount)
print("all_valid:", all_valid)


# Q19 - Debug an Input and Comparison Script
# Bug: input() returns text, so amount >= 100 raised a TypeError
# and :.2f on a string raised a ValueError.
# Fix: convert amount to float right after input().
city = input("City: ")
amount = float(input("Amount: "))

is_high_value = amount >= 100
print(f"{city} | £{amount:.2f} | High value: {is_high_value}")


# Q20 - Test Boundary Values
# Rule: high value when amount >= 100
print(99.99 >= 100)    # False - just below the limit
print(100.00 >= 100)   # True  - exactly on the boundary
print(100.01 >= 100)   # True  - just above the limit

# Why 100.00 matters: it is the only value where >= and > give different
# answers. If the code wrongly used > 100, 100.00 would fail. Bugs hide at boundaries.