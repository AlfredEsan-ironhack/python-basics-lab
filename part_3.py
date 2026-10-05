#question 9
amount = float(input("Enter order amount: "))
is_high_value = amount >= 100
print(is_high_value)
#if its 45.50, it will print False
#if its 125, it will print True

#question 10
# Case 1
status = "complete"
amount_gbp = 45.50
result = status == "complete" and amount_gbp > 0
print(result)  # True

# Case 2
status = "cancelled"
amount_gbp = 45.50
result = status == "complete" and amount_gbp > 0
print(result)  # False

# Case 3
status = "complete"
amount_gbp = -5.00
result = status == "complete" and amount_gbp > 0
print(result)  # False


#question 11
store = input("Store name: ")
amount = float(input("Order amount: "))
accepted = amount > 0
print(f"{store} order accepted: {accepted}")

#question 12
#answer is A: (true)