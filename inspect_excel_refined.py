import openpyxl
import sys

file_path = r"c:\Users\Lenovo\moalem-app\assets\files\كشف فارغ اعمال السنة من 3ل6 ابتدائى.xlsx"

try:
    wb = openpyxl.load_workbook(file_path, data_only=True)
    sheet = wb.active
    
    print(f"--- Header Inspection (Rows 5-8) ---")
    for r in range(5, 9):
        row_vals = []
        for c in range(1, 15): # Check first 15 columns (Metadata + Week 1 + start of Week 2)
            val = sheet.cell(row=r, column=c).value
            if val is not None:
                val = str(val).strip().replace('\n', ' ')
            row_vals.append(f"{c}:{val}")
        print(f"Row {r}: " + " | ".join(row_vals))

except Exception as e:
    print(f"Error: {e}")
