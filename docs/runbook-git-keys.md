# Runbook — Git & GitHub SSH / Deploy Key Setup

**Purpose:**  
Document the process for securely connecting a local development environment or CI system to GitHub using SSH keys or Personal Access Tokens (PAT).

---

## 🧩 1. Check for Existing Keys

```bash
ls -la ~/.ssh
Look for existing key pairs such as:

id_ed25519 and id_ed25519.pub

or id_rsa and id_rsa.pub

If none exist, create a new one.

🔑 2. Create a New SSH Key (User Key)
bash
Copy code
ssh-keygen -t ed25519 -C "your_email@example.com"
When prompted:

File location: press Enter to accept default ~/.ssh/id_ed25519

Passphrase: optional (recommended for security)

Start the agent and add the key:

bash
Copy code
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
Optional: make this persistent by adding the two lines above to your ~/.bashrc or ~/.profile.

⚙️ 3. Configure GitHub Host Entry (Recommended)
bash
Copy code
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat <<'EOF' >> ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
🔗 4. Add Public Key to GitHub
Display the public key:

bash
Copy code
cat ~/.ssh/id_ed25519.pub
Copy the entire line that starts with ssh-ed25519.

Add it to GitHub:

Navigate to GitHub → Settings → SSH and GPG keys → New SSH key

Paste the key and click Add SSH key

🧪 5. Test SSH Connection
bash
Copy code
ssh -T git@github.com
When prompted, type yes to trust the GitHub host key.

Expected output:

“Hi <username>! You've successfully authenticated…”

🏗️ 6. Initialize Local Repository and Configure Identity
From your project root (the folder containing README.md, docs/, and script/):

bash
Copy code
git init -b main
git config user.name  "<USER_FULL_NAME>"
git config user.email "<YOUR_EMAIL>"
git add .
git commit -m "chore(phase-0): initialize repo with bootstrap, docs, and ignore files"
🌐 7. Create Repository on GitHub and Link Remote
Option A — Web Interface
Create a new repo in GitHub (without README)

Link it locally:

bash
Copy code
git remote add origin git@github.com:<GITHUB_USERNAME>/<REPO_NAME>.git
git push -u origin main
Option B — GitHub CLI
bash
Copy code
gh auth login  # GitHub.com → SSH → authenticate
gh repo create <REPO_NAME> --private --source=. --remote=origin --push
⚙️ 8. Deploy Key Setup (For CI / Automation)
Use deploy keys when a machine (not your user account) needs access to a single repo.

bash
Copy code
ssh-keygen -t ed25519 -C "<REPO_NAME>-deploy-key" -f ~/.ssh/<REPO_NAME>_deploy
Add the public key (~/.ssh/<REPO_NAME>_deploy.pub) to:
GitHub → Repo → Settings → Deploy Keys → Add Key

Title: <REPO_NAME>-deploy-key

✅ Allow write access (if needed)

Optional host alias:

bash
Copy code
cat <<'EOF' >> ~/.ssh/config
Host github-<REPO_NAME>
  HostName github.com
  User git
  IdentityFile ~/.ssh/<REPO_NAME>_deploy
  IdentitiesOnly yes
EOF
Then set remote:

bash
Copy code
git remote add origin git@github-<REPO_NAME>:<GITHUB_USERNAME>/<REPO_NAME>.git
git push -u origin main
🌍 9. HTTPS + Personal Access Token (Fallback)
If SSH is blocked by network policy:

Create a Personal Access Token (PAT)
GitHub → Settings → Developer settings → Personal Access Tokens → Tokens (classic)
Scope: repo

Add remote and push:

bash
Copy code
git remote add origin https://github.com/<GITHUB_USERNAME>/<REPO_NAME>.git
git push -u origin main
When prompted for a password, use the token, not your GitHub password.

🧱 10. Post-Push Hardening
Branch Protection
GitHub → Repo → Settings → Branches → Add Rule

Branch name pattern: main

✅ Require pull request reviews before merging

✅ Require status checks to pass (CI/CD ready)

✅ Require linear history (optional)

Example Environment File
bash
Copy code
cat > .env.example <<'EOF'
# Example environment variables
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=changeme
EOF

git add .env.example
git commit -m "docs: add example environment file"
git push
License
Add an open-source license (MIT, Apache 2.0, etc.) if the repo is public.

🧯 Troubleshooting Quick Hits
Issue	Resolution
Permission denied (publickey)	Ensure key added to agent → ssh-add -l
Wrong remote URL	git remote -v → check; if wrong: git remote set-url origin git@github.com:<USER>/<REPO>.git
Host key verification prompt every time	Run ssh -T git@github.com once and accept
Accidentally committed secrets	Remove file → rotate secret → rewrite history (git filter-repo --path <file> --invert-paths)
“non-fast-forward” error	Pull with rebase: git pull --rebase origin main or overwrite with: git push --force-with-lease

✅ Validation Checklist
Check	Command	Expected
SSH Key Exists	ls ~/.ssh/id_ed25519*	2 files (.pub and private key)
GitHub Connection	ssh -T git@github.com	Authenticated success message
Remote Set	git remote -v	Shows correct origin URL
Branch Tracking	git branch -vv	origin/main linked
Push Works	git push	No errors

📦 Notes
Never commit .ssh/, .env, or credentials.

Keep .ssh/ and .env patterns in .gitignore.

Rotate keys yearly or if compromised.

Always verify your SSH connection before first push.

Status: ✅ Verified process

