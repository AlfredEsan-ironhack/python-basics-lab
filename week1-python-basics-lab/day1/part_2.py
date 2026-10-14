#question 5
order_count = 12
average_value = 36.75
store_name = "Leeds"
is_open = True

print(type(order_count))      # <class 'int'>
print(type(average_value))    # <class 'float'>
print(type(store_name))       # <class 'str'>
print(type(is_open))          # <class 'bool'>

#question 6
unit_price = 24.50
quantity = 3
delivery_fee = 4.99

subtotal = unit_price * quantity
final_total = subtotal + delivery_fee

print(f"{subtotal:.2f}")
print(f"{final_total:.2f}")

#question 7
quantity_text = "4"
price_text = "12.50"

quantity = int(quantity_text)
price = float(price_text)
total = quantity * price

print(total)  # 50.0

#question 8
#answer is D: Convert it with float()