# Multi-Cloud Deployment

## Prerequisites

- AWS, Azure, and GCP accounts. See [Cloud Specific Requirements](#cloud-specific-requirements) for more details on what is required from each provider.
- [Terraform](https://developer.hashicorp.com/terraform/install) installed
- Test SSH Keys. Be sure to put them somewhere other than `~/.ssh/id_rsa` to not interfere with any previously created keys.

  ```bash
  mkdir credentials && ssh-keygen -t rsa -f ./credentials/id_rsa -C adminuser -b 2048
  ```

## Deploy

TODO: Fill in Terraform init, plan, and apply commands.

## Cloud Specific Requirements

**NOTE:** These steps should **not** be used in a production environment. Only use these for testing/educational purposes. Roles/permissions should be scoped to the minimum permissions necessary, and the permissions given below are admin level.

Steps below assume each CLI is authenticated before attempting to run the commands.

### AWS

1. Create a user, replace `<username>` with the desired name.

   ```bash
   aws iam create-user --user-name <username>
   ```

2. Create access and secret access keys, replace `<username>` with the user name from step 1. **Be sure to save the output in a safe place!! Once completed the secret access key will no longer be visible.**

  ```bash
  aws iam create-access-key --user-name <username>
  ```

3. Attach policies so the user can create the necessary resources. Update `<username>` with the user name created in step 1.

  ```bash
  aws iam attach-user-policy 
  --user-name <username> 
  --policy-arn arn:aws:iam::aws:policy/job-function/NetworkAdministrator
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
  ```

### Azure

1. Get your Subscription and Tenant IDs using the command line and update the necessary fields in `azure/provider.tf`

   ```bash
   az account list
   ```

2. Create an Identity for Terraform to inherit and deploy resources, and assign permissions. These commands assume a default subscription is set. If not, it can be set using `az account set --subscription "My Subscription"`, changing "My Subscription" to your subscription name.

  ```bash
  # Create identity Resource Group
  az group create --name terraform-identity-rg --location eastus

  # Create the identity
  az identity create --name my-tf-identity --resource-group terraform-identity-rg

  # Assign permissions
  az role assignment create \
  --role Contributor \
  --assignee $(az identity show --name my-tf-identity --resource-group terraform-identity-rg --query principalId -o tsv) \
  --scope /subscriptions/<your-subscription-id>/resourceGroups/terraform-identity-rg

  # Assign the Network Contributor and Virtual Machine Contributor roles to the managed identity for the entire subscription
  az role assignment create \
  --assignee $(az identity show --name my-tf-identity --resource-group terraform-identity-rg --query principalId -o tsv) \
  --role "Network Contributor" \
  --role "Virtual Machine Contributor" \
  --scope "/subscriptions/<subscription_id>"
  ```

3. Get the client ID (application ID) and tenant ID for the managed identity. Update `client_id` in `azure/provider.tf` with the output value.

  ```bash
  # Get the client ID (application ID) and tenant ID for the managed identity
  az identity show \
  -n my-tf-identity \
  --resource-group terraform-identity-rg \
  --query "{clientId: clientId, tenantId: tenantId}" --output json
  ```

### GCP

1. GCP Service Account manually created via the console or using the command line. For this project the following permissions are required:

    - roles/compute.instanceAdmin
    - roles/compute.networkAdmin
    - roles/compute.firewallAdmin

    **NOTE:** The permissions above are broad and not intended for use in a production environment.

    ```bash
    gcloud iam service-accounts create SERVICE_ACCOUNT_NAME \
    --project PROJECT_ID \
    --display-name SERVICE_ACCOUNT_NAME \
    --description "Service account for VM and VPC network management"
    ```

    Bind roles to the newly created Service Account:

    ```bash
    gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SERVICE_ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin" \
    --role="roles/compute.networkAdmin" \
    ```

2. Create and download the JSON key file required for Terraform to have permission to create resources.

    ```bash
    cd gcp && gcloud iam service-accounts keys create KEY_FILE_NAME.json \
    --iam-account SERVICE_ACCOUNT_NAME@PROJECT_ID.iam.gserviceaccount.com
    ```

3. Update the file path in `gcp/variables.tf` for variable `gcp_key` to point to the newly created JSON key file.
