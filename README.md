# Terraform for Langfuse Self-Hosting on Google Cloud

![Google Cloud](https://img.shields.io/badge/Google%20Cloud-4285F4?logo=google-cloud&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-1.9.8-blue.svg)

## Overview
Terraform configuration for self-hosting [Langfuse](https://langfuse.com/) on Google Cloud.

![Langfuse v3 Architecture on Google Cloud](images/langfuse_v3_self_host_google_cloud.png)

## Update Langfuse v2 to v3
Our `main` branch will continuously support Langfuse v3. Langfuse v3 gained a solid and scalable architecture with the latest major update. You can also access v2 at `v0.0.1` tag.

## Differences with the base repo
1. Changes default locations of GCS bucket and Postgres instance to EU
2. Enable the following API in the project
    - Service Networking API
    - Cloud Filestore API
    - Google Cloud Memorystore for Redis API
3. Change the IP config for the VPC as the project policies doesn't allow ipv4_enabled (SSL can be added for more security)

## Setup
### Features
- Sreverless hosting on Cloud Run
- Secure data persistance with 
    - Cloud SQL 
    - Memorystore for Redis
    - Cloud Storage
    - Cloud Filestore (Mounted by Clickhouse on Cloud Run)
- Secure network with VPC

### Prerequisites
- Google Cloud account
- gcloud CLI installed
- Terraform installed

### Getting Started
1. Clone the repository and move directories
    ```
    git clone https://github.com/sotazum/langfuse-google-cloud-terraform.git
    cd terraform/google/environments/dev
    ```

2. Set your own variables on `terraform.tfvars`
   - Replace the value surrounded by `< >`

3. Comment out `web` module
    ```environments/dev/main.tf
    # # At initial terraform apply, the following resource "web" should be commented out to avoid an error. After pushing the image to the artifact registry, uncomment the resource "web" and apply the terraform configuration again.
    # module "web" {
    #   source = "../../modules/web"

    #   project_id        = var.project_id
    #   region            = var.region
    #   web_repository_id = var.web_repository_id
    #   langfuse_version  = var.langfuse_version
    #   network_name      = module.vpc.network_name
    #   subnet_name       = module.vpc.subnet_name

    #   env_web = local.env_web

    #   depends_on = [ module.worker ]
    # }
    ```

4. Google auth
    ```
    gcloud auth login --update-adc
    ```

5. 1st Terraform init and apply
    ```
    terraform init
    terraform apply
    ```

6. Push custom web image
    ```
    cd ../../../../
    bash ./docker/cloudbuild.sh <your-project-id> <your-region> langfuse-web-repo 3
    ```

    Note: If you are working with Windows, probably executing the scripts will raise an error. In that case convert all .sh scripts to Unix format:
    ```
    dos2unix cloudbuild.sh
    dos2unix down.sh
    dos2unix up.sh
    dos2unix drop.sh
    ```

    If pushing the image to the registry gives a permission error, you can upload manually the image:
    ```
    cd docker/web
    docker build -t europe-west2-docker.pkg.dev/<gcp_project>/langfuse-web-repo/langfuse/langfuse:3 . --no-cache
    docker push europe-west2-docker.pkg.dev/<gcp_project>/langfuse-web-repo/langfuse/langfuse:3
    ```
    (change the project_id with yours)

7. Migrate Terraform state to GCS
    ```
    cd ../../terraform/google/environments/dev
    terraform init -migrate-state
    ```
    - Then generate `backend.tf` and have Terraform state managed by a GCS bucket

8. Undo Comment out and 2nd Terraform apply
    ```environments/dev/main.tf
    # At initial terraform apply, the following resource "web" should be commented out to avoid an error. After pushing the image to the artifact registry, uncomment the resource "web" and apply the terraform configuration again.
    module "web" {
    source = "../../modules/web"

    project_id        = var.project_id
    region            = var.region
    web_repository_id = var.web_repository_id
    langfuse_version  = var.langfuse_version
    network_name      = module.vpc.network_name
    subnet_name       = module.vpc.subnet_name

    env_web = local.env_web

    depends_on = [ module.worker ]
    }
    ```

    ```
    terraform apply
    ```

9. Access to Langfuse

    - Check your Cloud Run URL on Google Cloud Console (default: `https://langfuse-web-<your-project-number>.<your-region>.run.app`)