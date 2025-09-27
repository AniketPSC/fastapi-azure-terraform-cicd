# 🚀 Cloud-Native FastAPI Microservice on Azure

## 📌 Project Overvie

This repository contains a small **Task Manager** microservice (CRUD) built with **FastAPI** and deployed to **Microsoft Azure** using a modern DevOps toolchain.

The full flow implemented in this project:

1. Build a RESTful Python microservice with FastAPI.
2. Write automated tests with **pytest**.
3. Containerize the app with **Docker**.
4. Provision cloud resources in Azure with **Terraform** (Resource Group, ACR, App Service Plan, Web App, Key Vault).
5. Automate build, test, push and deployment using **GitHub Actions** CI/CD.
6. Secure runtime secrets with **Azure Key Vault** and a system-assigned managed identity.

This project is demonstrating cloud-native application development, Infrastructure as Code, and CI/CD automation.

---

## 🛠️ Tech Stack

* **Language:** Python 3.11
* **Web framework:** FastAPI
* **Testing:** pytest
* **Containerization:** Docker
* **Infrastructure as Code:** Terraform (AzureRM provider)
* **Cloud provider:** Microsoft Azure

  * Azure App Service (Linux, Docker)
  * Azure Container Registry (ACR)
  * Azure Key Vault
* **CI/CD:** GitHub Actions
* **VCS:** Git + GitHub

---

## 🔧 Key Features

* REST API with full CRUD for Tasks (create, read, update, delete)
* Unit tests with pytest (automated in CI)
* Dockerfile for container image
* Terraform manifests to provision Azure resources
* GitHub Actions workflow to run tests, build Docker image, push to ACR, and update the Web App
* Azure Key Vault integration with a system-assigned Managed Identity to avoid storing secrets in source control

---

## 📂 Project Structure

```
cloud-native-fastapi-azure/
├── app/
│   ├── __init__.py
│   ├── main.py             # FastAPI app entrypoint
│   ├── models.py           # SQLAlchemy models
│   ├── database.py         # DB engine & session (handles in-memory testing)
│   └── ...                
├── tests/
│   └── test_api.py         # pytest unit tests
├── infra/
│   ├── providers.tf
│   ├── variables.tf
│   ├── locals.tf
│   ├── main.tf
│   └── outputs.tf
├── .github/
│   └── workflows/ci-cd.yml # GitHub Actions workflow
├── Dockerfile
├── requirements.txt
├── .gitignore
└── README.md
```

---

## 🚀 Quickstart — Run locally

Follow these exact commands.

```bash
# clone the repo
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>

# create & activate a virtual environment
python -m venv .venv
# macOS / Linux
source .venv/bin/activate
# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# run the app
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Open `http://127.0.0.1:8000/docs` to use the interactive Swagger UI.

---

## 🔁 Tests

Run tests locally before pushing to CI:

```bash
# activate venv first (see above)
pytest -q
```

Notes:

* The tests configure an in-memory SQLite database by setting `DATABASE_URL` to `sqlite:///:memory:` in test setup. The project uses `StaticPool` for SQLAlchemy when running in-memory so tests are reliable.

---

## 🐳 Docker

Build and run the container locally:

```bash
# build
docker build -t fastapi-todo:local .

# run
docker run --rm -p 8000:8000 fastapi-todo:local
```

Visit `http://127.0.0.1:8000/docs` to confirm.

---

## 🧱 Infrastructure (Terraform)

Terraform files live in `/infra`. They provision:

* Resource Group
* Azure Container Registry (ACR)
* App Service Plan (Linux)
* App Service (Web App) configured for Docker
* Azure Key Vault + a sample secret

Quick commands (from infra/):

```bash
cd infra
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Outputs (ACR login server, Web App hostname, Key Vault URI) will be printed and available via `terraform output`.

---

## 🔐 GitHub Actions CI/CD

Workflow location: `.github/workflows/ci-cd.yml`.

What it does on `push` to `main`:

1. Checkout code
2. Set up Python, install dependencies, run pytest
3. Login to Azure via `azure/login` (service principal JSON stored in `AZURE_CREDENTIALS` secret)
4. Log into ACR and build/push the Docker image
5. Configure the Azure Web App to use the new container image
6. Restart the Web App

**Required GitHub secrets** (store under Settings → Secrets → Actions):

* `AZURE_CREDENTIALS` — the JSON from `az ad sp create-for-rbac --sdk-auth` (service principal)
* `ACR_NAME` — the short ACR name
* `ACR_LOGIN_SERVER` — full ACR login server (e.g. `youracr.azurecr.io`)
* `WEBAPP_NAME` — the App Service name
* `RG_NAME` — the Resource Group name
* `KEY_VAULT_URI` — (optional) if your app uses Key Vault at runtime

---

## 🔑 Key Vault & Managed Identity

* The Web App is created with a **system-assigned managed identity**.
* Terraform grants that identity `Get`/`List` permission to the Key Vault secrets.
* Local development can use `az login` or environment variables (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`) to emulate authentication with `DefaultAzureCredential`.

---

## 🔍 Verify Deployment 

Create a task via curl:

```bash
curl -X POST "https://<WEBAPP_NAME>.azurewebsites.net/tasks" -H "Content-Type: application/json" -d '{"title":"Hello","description":"from curl"}'

# list tasks
curl "https://<WEBAPP_NAME>.azurewebsites.net/tasks"
```

---


