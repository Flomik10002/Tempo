import os

ROOT_DIR = "/home/flomik/StudioProjects/Tempo/lib"              # какую директорию сканировать
OUTPUT_FILE = "dump.txt"    # итоговый файл

def is_binary(path, blocksize=512):
    try:
        with open(path, "rb") as f:
            return b"\0" in f.read(blocksize)
    except:
        return True

with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
    for root, _, files in os.walk(ROOT_DIR):
        for name in files:
            path = os.path.join(root, name)

            if path == OUTPUT_FILE:
                continue

            if is_binary(path):
                continue

            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    data = f.read()
            except Exception as e:
                data = f"[ERROR READING FILE: {e}]"

            out.write(f"{path} {name}\n")
            out.write(data)
            out.write("\n\n" + "="*80 + "\n\n")
