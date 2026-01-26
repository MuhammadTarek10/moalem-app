import xml.etree.ElementTree as ET
import os

base_path = "c:\\Users\\Lenovo\\moalem-app\\temp_excel_analysis_2\\xl"
shared_strings_path = os.path.join(base_path, "sharedStrings.xml")
sheet_path = os.path.join(base_path, "worksheets", "sheet1.xml")

def get_shared_strings():
    if not os.path.exists(shared_strings_path):
        return []
    tree = ET.parse(shared_strings_path)
    root = tree.getroot()
    # clean namespace
    ns = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
    strings = []
    for si in root.findall(f"{ns}si"):
        t = si.find(f"{ns}t")
        if t is not None:
            strings.append(t.text)
        else:
            strings.append("") 
    return strings

def parse_sheet(shared_strings):
    tree = ET.parse(sheet_path)
    root = tree.getroot()
    ns = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
    
    sheet_data = root.find(f"{ns}sheetData")
    
    output = []
    output.append("Excel Content Preview:")
    for row in sheet_data.findall(f"{ns}row"):
        r_idx = row.get("r")
        row_cells = []
        for cell in row.findall(f"{ns}c"):
            c_ref = cell.get("r")
            t_type = cell.get("t")
            v_val = cell.find(f"{ns}v")
            
            value = ""
            if v_val is not None:
                if t_type == "s": # shared string
                    idx = int(v_val.text)
                    if idx < len(shared_strings):
                        value = shared_strings[idx]
                    else:
                        value = f"STR#{idx}"
                else:
                    value = v_val.text
            
            row_cells.append(f"{c_ref}: {value}")
        
        output.append(f"Row {r_idx}: " + " | ".join(row_cells))
        
        if int(r_idx) > 25: # Limit output slightly more
            break

    # Also check for merged cells
    merge_cells = root.find(f"{ns}mergeCells")
    if merge_cells is not None:
        output.append("\nMerged Cells:")
        for merge in merge_cells.findall(f"{ns}mergeCell"):
            output.append(merge.get("ref"))
            
    with open("analysis_output.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(output))

try:
    shared = get_shared_strings()
    parse_sheet(shared)
    print("Done")
except Exception as e:
    print(f"Error parsing XML: {e}")
