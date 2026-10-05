# Q16 - Debugging
# Answer: C - convert price to float before multiplying
price = "12.50"
total = float(price) * 2
print(total)  # 25.0