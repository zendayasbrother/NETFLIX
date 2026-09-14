# Netflix Clone Monorepo: Full-Stack Cloud Deployment

A **production-grade monorepo** implementation of a Netflix-style streaming application. This project demonstrates comprehensive full-stack engineering with containerized microservices, automated CI/CD pipelines, cloud database orchestration, and infrastructure-as-code practices.

## Technical Architecture

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React SPA, React Router, Axios, Custom CSS |
| **Backend** | Spring Boot (Java), Maven, REST API |
| **Database** | MongoDB Atlas (AWS eu-north-1) |
| **Containerization** | Docker, Docker Compose |
| **CI/CD** | GitHub Actions, Amazon ECR |
| **Infrastructure** | AWS (ECR, IAM, Secrets Manager) |

### Language Composition
- **JavaScript**: 43.5% (Frontend)
- **Java**: 28.6% (Backend)
- **CSS**: 14.7% (Styling)
- **HTML**: 7.3% (Markup)
- **Dockerfile**: 5.9% (Container Config)

---

## 📋 Deployment & Setup Guide

### Phase 1: Local Monorepo Initialization & Source Control

I converted the individual upstream repositories into a unified monorepo architecture by consolidating Git histories and establishing a clean root repository.

#### Cloned Upstream Repositories

I started by cloning both the frontend and backend code from their original locations:

```bash
git clone https://github.com/digitalwitchdemo/netflix_backend.git
git clone https://github.com/digitalwitchdemo/netflix_frontend.git
```

#### Initialized Root Repository

I removed the existing nested Git instances to convert them into tracked directories:

```bash
rm -rf netflix_backend/.git netflix_frontend/.git
```

I then initialized the root repository and configured the remote origin:

```bash
git init
git branch -M main
git remote add origin https://github.com/zendayasbrother/NETFLIX.git
```

I performed the initial cumulative commit and push:

```bash
git add .
git commit -m "feat: setup monorepo structure for frontend and backend"
git push -u origin main
```

**Output:**
```
Initialized empty Git repository in ./NETFLIX/.git/
[main (root-commit) abc1234] feat: setup monorepo structure for frontend and backend
 2 files changed, ...
Enumerating objects: ..., done.
Counting objects: 100% (...), done.
Writing objects: 100% (...), done.
```

---

### Phase 2: Database Provisioning (MongoDB Atlas)

I set up MongoDB Atlas as the cloud database solution for storing and managing the movie catalog.

#### Created the Cluster

I navigated to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) and signed up with MFA enabled. I created a **free shared cluster** named `Cluster0` and selected **AWS** as the cloud provider, deploying to the `eu-north-1` region.

#### Configured Access Control

I configured database user authentication by creating a database user with secure credentials. I restricted network IP access via IP Whitelist and downloaded the `.env` file for secure credential storage.

#### Set Up Database & Collection

I created a database named `movies` containing a `movies` collection to hold dynamic catalog records. The collection stores structured movie metadata with strict JSON schemas:

```javascript
// Collection: movies
{
  "imdbId": "tt1234567",
  "title": "Example Movie",
  "backdrops": ["url1", "url2"],
  "genres": ["Action", "Sci-Fi"]
}
```

#### Added the Connection String

I copied the MongoDB connection string from the **Drivers** section and added it to my `.env` file:

```bash
MONGO_URI=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/movies?retryWrites=true&w=majority
```

#### Verified Installation & Setup

I installed Node.js and tested the connection by ensuring both `package.json` files existed in the backend and frontend subdirectories:

```bash
node --version  # Verified Node.js installation
npm install     # Installed dependencies
npm start       # Started the frontend server
```

**Troubleshooting:** Initially, I encountered issues running the frontend server. I resolved this by verifying that `package.json` files existed in both subdirectories and reinstalling npm to legitimize the installation.

---

### Phase 3: CI/CD Pipeline & Amazon ECR Integration

I engineered automated container deployment workflows using GitHub Actions to build Docker images and push them to AWS ECR on every push to `main`.

#### Created AWS ECR Repositories

I navigated to the **AWS ECR Console** in the `eu-north-1` region and created two **private repositories**:
- `netflix-backend`
- `netflix-frontend`

I left all settings on default, keeping both repositories private.

#### Generated IAM & Secrets Configuration

I generated programmatic access keys via the AWS IAM Console:

1. Went to **IAM Console > Users > [My IAM User]**
2. Selected **Security Credentials > Generate Access Key > App running outside AWS**
3. Copied both the Access Key ID and Secret Access Key

I then registered these keys as **GitHub Repository Secrets**:

1. Navigated to my repository: **Settings > Secrets and Variables > Actions**
2. Created two new secrets:
   - `AWS_ACCESS_KEY_ID` (pasted the Access Key ID)
   - `AWS_SECRET_ACCESS_KEY` (pasted the Secret Access Key)

**Example:**
```
Secret Name: AWS_ACCESS_KEY_ID
Value: AKIAIOSFODNN7EXAMPLE

Secret Name: AWS_SECRET_ACCESS_KEY
Value: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

#### Created GitHub Actions Workflows

I created workflow files under `.github/workflows/` to handle continuous integration and automated image tagging.

##### Backend Workflow

I created `.github/workflows/backend.yml` to automate backend deployment:

```yaml
name: Deploy Backend to ECR

on:
  push:
    branches:
      - main
    paths:
      - 'netflix_backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-north-1

      - name: Login to Amazon ECR
        run: aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-north-1.amazonaws.com

      - name: Build Docker image
        run: docker build -t netflix-backend:latest ./netflix_backend

      - name: Tag and push to ECR
        run: |
          docker tag netflix-backend:latest ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-north-1.amazonaws.com/netflix-backend:latest
          docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-north-1.amazonaws.com/netflix-backend:latest
```

##### Frontend Workflow

I created `.github/workflows/frontend.yml` to automate frontend deployment:

```yaml
name: Deploy Frontend to ECR

on:
  push:
    branches:
      - main
    paths:
      - 'netflix_frontend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-north-1

      - name: Login to Amazon ECR
        run: aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-north-1.amazonaws.com

      - name: Build Docker image
        run: docker build -t netflix-frontend:latest ./netflix_frontend

      - name: Tag and push to ECR
        run: |
          docker tag netflix-frontend:latest ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-north-1.amazonaws.com/netflix-frontend:latest
          docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.eu-north-1.amazonaws.com/netflix-frontend:latest
```

---

## 🚀 Key Features & Engineering Practices

✅ **Monorepo Architecture** – Unified repository for frontend, backend, and configuration  
✅ **Infrastructure as Code** – GitHub Actions workflows enable automated deployment  
✅ **Cloud Database** – MongoDB Atlas provides scalability and high availability  
✅ **Security** – AWS IAM roles, Secrets Manager, and IP whitelisting  
✅ **CI/CD Automation** – Push-to-deploy pipeline with automatic image tagging  

---

## 📂 Repository Structure

```
NETFLIX/
├── netflix_backend/          # Spring Boot microservices
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── netflix_frontend/         # React SPA
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── .github/
│   └── workflows/
│       ├── backend.yml
│       └── frontend.yml
└── README.md
```

---

## 📝 License

This project is open-source and available under the MIT License.

---

**Built with ❤️ by [zendayasbrother](https://github.com/zendayasbrother)**
