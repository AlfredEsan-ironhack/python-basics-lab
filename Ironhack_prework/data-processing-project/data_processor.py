import json
import os
import csv
 
def read_orders(file_path):
    """
    Reads order data from a JSON file.
    Returns a list of orders or empty list if error occurs.
    """
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            print(f"*Successfully read {len(data)} orders from {file_path}")
            return data
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        return []
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in file '{file_path}'.")
        return []
    except Exception as e:
        print(f"Unexpected error: {e}")
        return []


def clean_customer_name(name):
    """
    Cleans customer name by removing whitespace and converting to title case.
    Example: "  john doe  " -> "John Doe"
    """
    return name.strip().title()


def validate_order(order):
    """
    Validates that an order has all required fields and valid data types.
    Returns True if valid, False otherwise.
    """
    try:
        # Check if all required fields exist
        required_fields = ["order_id", "customer_name", "product", "quantity", "price", "order_date"]
        for field in required_fields:
            if field not in order:
                print(f"   Order {order.get('order_id')} missing field: {field}")
                return False
        
        # Validate quantity is a positive integer
        try:
            quantity = int(order["quantity"]) if isinstance(order["quantity"], str) else order["quantity"]
            if quantity <= 0:
                print(f"   Order {order['order_id']} has invalid quantity: {quantity}")
                return False
        except (ValueError, TypeError):
            print(f"   Order {order['order_id']} has invalid quantity: {order['quantity']}")
            return False
        
        # Validate price is a positive float
        try:
            price = float(order["price"]) if isinstance(order["price"], str) else order["price"]
            if price <= 0:
                print(f"   Order {order['order_id']} has invalid price: {price}")
                return False
        except (ValueError, TypeError):
            print(f"   Order {order['order_id']} has invalid price: {order['price']}")
            return False
        
        return True
    
    except Exception as e:
        print(f"  [ERROR] Unexpected error validating order: {e}")
        return False

#data cleaning function
def normalize_order(order):
    """
    Normalizes an order by cleaning names and converting data types.
    Example: Converts quantity "2" -> 2, price "899.99" -> 899.99
    """
    try:
        normalized = {
            "order_id": order["order_id"],
            "customer_name": clean_customer_name(order["customer_name"]),
            "product": order["product"],
            "quantity": int(order["quantity"]) if isinstance(order["quantity"], str) else order["quantity"],
            "price": float(order["price"]) if isinstance(order["price"], str) else order["price"],
            "order_date": order["order_date"]
        }
        return normalized
    except Exception as e:
        print(f"   Error normalizing order {order.get('order_id')}: {e}")
        return None
def remove_duplicates(orders):
    """
    Removes duplicate orders by keeping only the first occurrence of each order_id.
    Example: [ORD001, ORD002, ORD001] -> [ORD001, ORD002]
    """
    seen_ids = set()
    unique_orders = []
    
    for order in orders:
        order_id = order["order_id"]
        if order_id not in seen_ids:
            seen_ids.add(order_id)
            unique_orders.append(order)
        else:
            print(f"  [REMOVED] Duplicate removed: {order_id} (keeping first occurrence)")
    
    return unique_orders

def process_orders(orders):
    """
    Main processing function that orchestrates the entire cleaning pipeline.
    Steps:
    1. Validate each order
    2. Normalize valid orders (clean data types and formatting)
    3. Remove duplicates (keep first occurrence of each order_id)
    
    Returns: List of cleaned, unique orders
    """
    print("\n" + "=" * 50)
    print("PROCESSING PIPELINE")
    print("=" * 50)
    
    # Step 1: Validate and collect valid orders
    print("\n[Step 1] Validating orders...")
    valid_orders = []
    invalid_count = 0
    for order in orders:
        if validate_order(order):
            valid_orders.append(order)
        else:
            invalid_count += 1
    print(f"  [OK] {len(valid_orders)} valid orders, {invalid_count} invalid orders removed")
    
    # Step 2: Normalize valid orders
    print("\n[Step 2] Normalizing data (cleaning formatting, converting types)...")
    normalized_orders = []
    for order in valid_orders:
        normalized = normalize_order(order)
        if normalized:
            normalized_orders.append(normalized)
    print(f"  [OK] {len(normalized_orders)} orders normalized")
    
    # Step 3: Remove duplicates
    print("\n[Step 3] Removing duplicates...")
    unique_orders = remove_duplicates(normalized_orders)
    print(f"  [OK] {len(unique_orders)} unique orders after deduplication")
    
    print("\n" + "=" * 50)
    print("PROCESSING COMPLETE")
    print("=" * 50)
    
    return unique_orders

def calculate_summary(orders):
    """
    Calculates summary statistics from cleaned orders.
    
    Returns a dictionary with:
    - total_orders: Number of orders
    - total_revenue: Sum of (quantity × price) for all orders
    - most_ordered_product: The product ordered most frequently
    """
    if not orders:
        return {
            "total_orders": 0,
            "total_revenue": 0.0,
            "most_ordered_product": "N/A"
        }
    
    # Calculate total orders
    total_orders = len(orders)
    
    # Calculate total revenue (sum of quantity * price)
    total_revenue = sum(order["quantity"] * order["price"] for order in orders)
    
    # Find most ordered product
    product_quantities = {}
    for order in orders:
        product = order["product"]
        quantity = order["quantity"]
        if product in product_quantities:
            product_quantities[product] += quantity
        else:
            product_quantities[product] = quantity
    
    most_ordered_product = max(product_quantities, key=product_quantities.get)
    
    # Create summary dictionary
    summary = {
        "total_orders": total_orders,
        "total_revenue": total_revenue,
        "most_ordered_product": most_ordered_product
    }
    
    return summary

def write_csv(orders, file_path):
    """
    Writes cleaned orders to a CSV file.
    
    Parameters:
    - orders: List of cleaned order dictionaries
    - file_path: Path where CSV file should be saved
    """
    try:
        with open(file_path, 'w', newline='') as csvfile:
            # Define the column headers
            fieldnames = ['order_id', 'customer_name', 'product', 'quantity', 'price', 'order_date']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            # Write the header row
            writer.writeheader()
            
            # Write all order rows
            writer.writerows(orders)
            
            print(f"[OK] Successfully wrote {len(orders)} orders to {file_path}")
            return True
    
    except IOError as e:
        print(f"[ERROR] Error writing to file '{file_path}': {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Unexpected error writing CSV: {e}")
        return False


def write_summary(summary, file_path):
    """
    Writes summary statistics to a text file.
    
    Parameters:
    - summary: Dictionary with summary statistics
    - file_path: Path where summary file should be saved
    """
    try:
        with open(file_path, 'w') as f:
            f.write("=" * 50 + "\n")
            f.write("DATA CLEANING SUMMARY REPORT\n")
            f.write("=" * 50 + "\n\n")
            
            f.write("STATISTICS\n")
            f.write("-" * 50 + "\n")
            f.write(f"Total Orders Processed: {summary['total_orders']}\n")
            f.write(f"Total Revenue: ${summary['total_revenue']:.2f}\n")
            f.write(f"Most Ordered Product: {summary['most_ordered_product']}\n")
            f.write("\n" + "=" * 50 + "\n")
        
        print(f"[OK] Successfully wrote summary to {file_path}")
        return True
    
    except IOError as e:
        print(f"[ERROR] Error writing to file '{file_path}': {e}")
        return False
    except Exception as e:
        print(f"[ERROR] Unexpected error writing summary: {e}")
        return False

def main():
    """
    Main execution function that orchestrates the entire data processing workflow.
    """
    print("\n" + "=" * 50)
    print("DATA PROCESSING PIPELINE")
    print("=" * 50 + "\n")
    
    # Define file paths
    input_file = "data/orders.json"
    output_csv = "output/cleaned_orders.csv"
    output_summary = "output/summary.txt"
    
    # Step 1: Read raw data
    print(f"[1/6] Reading data from {input_file}...")
    orders = read_orders(input_file)
    if not orders:
        print("[ERROR] Failed to read orders. Exiting.")
        return
    print(f"[OK] Loaded {len(orders)} raw orders\n")
    
    # Step 2: Process all orders through the pipeline
    print("[2/6] Processing orders through cleaning pipeline...\n")
    cleaned_orders = process_orders(orders)
    print()
    
    # Step 3: Display final results
    print("[3/6] Displaying cleaned orders...\n")
    print("=" * 50)
    print("CLEANED ORDERS")
    print("=" * 50)
    print(f"\nTotal: {len(cleaned_orders)} orders\n")
    
    for i, order in enumerate(cleaned_orders, 1):
        print(f"{i}. Order ID: {order['order_id']}")
        print(f"   Customer: {order['customer_name']}")
        print(f"   Product: {order['product']}")
        print(f"   Quantity: {order['quantity']}")
        print(f"   Price: ${order['price']:.2f}")
        print(f"   Total: ${order['quantity'] * order['price']:.2f}")
        print(f"   Date: {order['order_date']}")
        print()
    
    # Step 4: Calculate summary statistics
    print("[4/6] Calculating summary statistics...")
    summary = calculate_summary(cleaned_orders)
    
    print("\n" + "=" * 50)
    print("SUMMARY STATISTICS")
    print("=" * 50)
    print(f"\nTotal Orders: {summary['total_orders']}")
    print(f"Total Revenue: ${summary['total_revenue']:.2f}")
    print(f"Most Ordered Product: {summary['most_ordered_product']}\n")
    
    # Step 5: Write CSV output
    print("[5/6] Writing cleaned data to CSV file...")
    csv_success = write_csv(cleaned_orders, output_csv)
    print()
    
    # Step 6: Write summary output
    print("[6/6] Writing summary report to text file...")
    summary_success = write_summary(summary, output_summary)
    print()
    
    # Final status
    print("=" * 50)
    if csv_success and summary_success:
        print("[OK] ALL PROCESSING COMPLETE - SUCCESS!")
        print("=" * 50)
        print(f"\nOutput files created:")
        print(f"  • {output_csv}")
        print(f"  • {output_summary}")
        print()
    else:
        print("[ERROR] PROCESSING COMPLETE - SOME ERRORS OCCURRED")
        print("=" * 50)
    
    return cleaned_orders, summary


if __name__ == "__main__":
    main()