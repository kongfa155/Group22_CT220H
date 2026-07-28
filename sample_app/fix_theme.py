import os

mappings = {
    "bodyText1": "bodyLarge",
    "headline1": "displayLarge",
    "headline2": "displayMedium",
    "headline3": "displaySmall",
    "headline6": "titleLarge",
}

for root, _, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r") as f:
                content = f.read()
            
            modified = content
            for old, new in mappings.items():
                modified = modified.replace(old, new)
                
            if modified != content:
                with open(filepath, "w") as f:
                    f.write(modified)
                print(f"Updated {filepath}")
