import os
import json

def find_error_files(directory):
    error_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith("_error.json"):
                error_files.append(os.path.join(root, file))
    return error_files

def extract_error_details(file_path):
    try:
        with open(file_path, 'r') as file:
            data = json.load(file)
            # Assuming the JSON structure has keys like 'status_code' and 'message'
            return {
                'path': file_path,
                'status_code': data.get('error', {}).get('code'),
                'message': data.get('error', {}).get('message')
            }
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return None

def main():
    error_files = find_error_files('results/get-err')  
    error_details = [extract_error_details(file) for file in error_files if extract_error_details(file)]

    error_summary = {"error_details": error_details} if error_details else {}

    with open('get-err-files.json', 'w') as json_file:
        json.dump(error_summary, json_file, indent=4)

if __name__ == "__main__":
    main()
