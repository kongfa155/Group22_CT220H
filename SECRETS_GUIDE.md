# GitHub Actions Secrets Guide

To automatically build and sign a Release APK in GitHub Actions, you need to provide your repository with a signing keystore and its credentials. We pass these securely using **GitHub Secrets**.

Here is a step-by-step guide to generating these 4 required secrets.

## Step 1: Generate a Keystore (if you haven't already)
A keystore is a file containing the private key used to sign your Android app.

Run this command in your terminal (macOS/Linux):
```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
* It will prompt you for a **password**. Enter a strong password (e.g., `flutter_secret`) and remember it.
* It will ask for your name and organization details. You can fill these out or leave them blank/unknown.
* The tool will generate a file called `release.jks`.
* **Important:** Keep this file safe and never commit it to your public repository! (It is currently ignored by `.gitignore`).

## Step 2: Convert the Keystore to Base64
GitHub Secrets can only store text, not binary files like `.jks`. To store the file, we convert it into a Base64 string.

Run this command in the same directory as your `release.jks` file:
```bash
base64 -i release.jks > keystore_base64.txt
```
This will create a `keystore_base64.txt` file containing a very long block of text.

## Step 3: Add the Secrets to GitHub
1. Open your repository on GitHub in your browser.
2. Go to **Settings** (the gear icon tab).
3. On the left sidebar, scroll down to **Secrets and variables** and click **Actions**.
4. Click the green **New repository secret** button four times to add the following secrets:

| Secret Name | What to paste in the Value field |
| :--- | :--- |
| `KEY_ALIAS` | `upload` (or whatever alias you used in Step 1) |
| `KEY_PASSWORD` | The password you entered in Step 1 |
| `STORE_PASSWORD` | The password you entered in Step 1 (usually the same as KEY_PASSWORD) |
| `KEYSTORE_BASE64` | Open `keystore_base64.txt` in a text editor, copy the **entire** contents, and paste it here. |

## Step 4: Clean up
Once the secrets are safely stored in GitHub, delete the text file containing the Base64 string to keep your local environment clean:
```bash
rm keystore_base64.txt
```

You're done! Your GitHub Actions CI/CD pipeline now has everything it needs to sign your APKs for release.
