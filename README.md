# Netflix Full-Stack Deployment

This repository contains a full-stack Netflix-style application made up of a frontend and backend, deployed with Docker on AWS. The project documents my process of bringing two separate codebases together, connecting the application to MongoDB Atlas, automating image builds with GitHub Actions, and deploying the containers through Portainer.

The repository is composed of:

- **Frontend:** JavaScript, HTML and CSS
- **Backend:** Java and Maven
- **Database:** MongoDB Atlas
- **Containerisation:** Docker
- **CI/CD:** GitHub Actions and Amazon ECR
- **Deployment:** AWS EC2 and Portainer

---

## Phase 1 — Git and Initialising the Repository

I began by cloning the frontend and backend repositories into my VS Code workspace. I initially cloned both projects separately and accidentally created duplicate Git structures. To correct this, I removed the existing Git metadata and converted the two projects into one repository.

```bash
git clone <original-backend-repository>
git clone <original-frontend-repository>

rm -rf .git
git init
git branch -M main
git remote add origin https://github.com/zendayasbrother/NETFLIX.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

This left me with a monorepo containing both application layers:

```text
NETFLIX/
├── netflix_backend/
└── netflix_frontend/
```

This stage was useful because it made the relationship between the frontend and backend clearer. Rather than managing two unrelated deployments, I could work from one repository and later build each part independently through its own workflow.

---

## Phase 2 — Deploying MongoDB

I created a MongoDB Atlas account and enabled multi-factor authentication before provisioning the database. I selected the free option, kept the cluster name as `Cluster0`, and allowed Atlas to provision the cluster on AWS in the `eu-north-1` region.

I then created a database and collection named `movies`. The collection was intended to store the application's movie data.

From the **Drivers** connection method, I copied the MongoDB connection string and added it to the environment configuration used by the backend. The credentials and connection string were kept out of the source code.

Example configuration:

```env
MONGO_DATABASE=movies
MONGO_CLUSTER=mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/movies?retryWrites=true&w=majority
```

I also installed Node.js and checked that both subdirectories contained their own `package.json` files. After reinstalling the required npm dependencies, I was able to run the frontend locally and continue testing the application.

This phase showed me that the application could not be treated as only a frontend or backend exercise. The database had to be provisioned and configured before the backend could operate properly.

---

## Phase 3 — GitHub Actions and Amazon ECR

The original backend workflow used GitLab configuration, so I changed the workflow to use GitHub Actions. The purpose of the workflow was to build Docker images and push them to Amazon Elastic Container Registry (ECR).

I created two private ECR repositories:

- `netflix-backend`
- `netflix-frontend`

I then added the required AWS values under **GitHub repository → Settings → Secrets and variables → Actions**. The credentials were stored as GitHub secrets so they were not written directly into the workflow files.

The workflow process was designed to:

1. Check out the repository.
2. Configure AWS credentials.
3. Log in to Amazon ECR.
4. Build the relevant Docker image.
5. Tag the image with the ECR repository address.
6. Push the image to ECR.

The backend image followed this general pattern:

```bash
docker build -t netflix-backend:latest ./netflix_backend
docker tag netflix-backend:latest <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/netflix-backend:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/netflix-backend:latest
```

The frontend used the same process, but pointed to `./netflix_frontend` and the `netflix-frontend` ECR repository.

I generated the AWS access keys through IAM and added them to GitHub as secrets. In retrospect, these credentials should be restricted to only the permissions required by the workflow, and any temporary or placeholder credentials should be removed or rotated after testing.

---

## Phase 4 — Docker, Portainer and Deployment

For the final phase, I created an Ubuntu-based EC2 instance to act as the Docker host. I selected a `t3.micro` instance and configured the security group to allow the traffic required by the application while restricting SSH access to my own IP address.

The inbound rules were configured as follows:

- **22 — SSH:** My IP only
- **80 — HTTP:** Anywhere
- **443 — HTTPS:** Anywhere
- **5000 — Backend:** Anywhere, for testing the backend service

Docker was already available in my environment. I also enabled Docker's WSL integration through Docker Desktop by going to **Resources → WSL Integration**, enabling integration, and selecting Ubuntu.

I verified Docker from Ubuntu and installed Portainer with the following command:

```bash
wsl -d Ubuntu
docker --version
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

I initially encountered a problem while creating the Portainer account and became stuck in a timeout loop. I removed the Portainer container and its data volume, then recreated it with an administrator password file:

```bash
docker rm -f portainer
docker volume rm portainer_data

echo -n "<PORTAINER_PASSWORD>" > /tmp/portainer_pass

docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  -v /tmp/portainer_pass:/tmp/portainer_pass \
  portainer/portainer-ce:latest \
  --admin-password-file=/tmp/portainer_pass
```

I then created a separate IAM user for Portainer and attached the `AmazonEC2ContainerRegistryFullAccess` policy so that Portainer could authenticate with ECR. In Portainer, I added the backend and frontend ECR repositories as registries and enabled authentication using the IAM access key and secret access key.

Finally, I created a cumulative Portainer stack referencing both ECR images and the MongoDB configuration. The stack allowed the frontend and backend containers to run together on the Docker host while the backend connected to MongoDB Atlas.

A simplified version of the stack configuration was:

```yaml
services:
  backend:
    image: <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/netflix-backend:latest
    container_name: netflix-backend
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      MONGO_DATABASE: ${MONGO_DATABASE}
      MONGO_CLUSTER: ${MONGO_CLUSTER}

  frontend:
    image: <AWS_ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/netflix-frontend:latest
    container_name: netflix-frontend
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - backend
```

The actual port mappings must match the ports exposed by the Dockerfiles and the ports used by the Spring Boot application. After deploying the stack, I checked Portainer to confirm that both containers were running and used their logs to identify any startup or connection problems.

The resulting deployment flow was:

```text
GitHub
   ↓
GitHub Actions
   ↓
Amazon ECR
   ↓
Portainer on AWS EC2
   ↓
Frontend and backend containers
   ↓
MongoDB Atlas
```

This final phase brought together the earlier work. GitHub stored the code, Actions built and published the images, ECR stored the private images, Portainer pulled and managed them, and MongoDB Atlas provided the application's persistent data layer.

---

## Reflection

The deployment was not completely linear. I had to correct the initial Git setup, troubleshoot the frontend dependencies, convert the workflow from GitLab to GitHub Actions, and resolve the Portainer setup timeout. Each problem made the architecture clearer and helped me understand how the individual services depended on one another.

The most important lessons were:

- A monorepo needs one clear Git root when multiple applications are managed together.
- Database provisioning and network access must be completed before the backend can be tested reliably.
- GitHub Actions secrets and AWS IAM permissions need to be configured deliberately.
- Docker image ports, application ports, and EC2 security-group ports must all agree.
- Deployment credentials and database credentials should never be committed to the repository.
- Portainer provides a practical interface for pulling and managing private container images on an EC2 Docker host.

For a production deployment, I would further restrict IAM permissions, avoid exposing the backend directly where possible, use HTTPS with a domain and reverse proxy, and rotate any credentials used during development or testing.

---

## Repository Structure

```text
NETFLIX/
├── netflix_backend/
├── netflix_frontend/
├── .github/
│   └── workflows/
└── README.md
```

---

## Security Note

Do not commit real MongoDB connection strings, AWS access keys, Portainer passwords, or other credentials. Replace the placeholders in this document with environment variables or GitHub/AWS secrets when configuring the application.
