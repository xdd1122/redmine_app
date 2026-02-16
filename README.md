# 🚀 Redmine on AWS (Terraform + Docker)

This project allows you to deploy a secure, production-ready Redmine application to Amazon Web Services (AWS) from scratch.

The **Development approach**:  We build the entire application (including plugins and dependencies), save it as a single file, and then upload it to the server. This makes the server very stable and easy to manage.

There are two ways of setting up the environment, 
1. **[1. The AWS  - Cloud hosted way](#aws-setup)**
2. **[2. Locally via Multipass](#local-setup)**

---

## 🛠️ Step 0: Prerequisites
1.  **[Docker Desktop](https://www.docker.com/products/docker-desktop/)**: Required to build the application image.
2.  **[Terraform](https://developer.hashicorp.com/terraform/downloads)**: Required to create the server on AWS automatically.
3.  **[AWS CLI](https://aws.amazon.com/cli/)**: Required to connect your computer to your AWS account.
4.  **Git**: To download this project.

---

<div id="aws-setup"></div>

## 🔑 Step 1: Connect to AWS

Terraform needs permission to create servers in your AWS account.

1.  **Create an AWS Account:** If you don't have one, sign up at [aws.amazon.com](https://aws.amazon.com).
2.  **Create Access Keys:**
    * Go to the **IAM Dashboard** in the AWS Console.
    * Click **Users** > **Create User** (name it `terraform-user`).
    * Attach policies: Select **AdministratorAccess**.
    * Once created, go to the user's **Security Credentials** tab.
    * Click **Create Access Key**.
    * **SAVE the Access Key ID and Secret Access Key.**
3.  **Configure your Computer:**
    Open your terminal and run:
    ```bash
    aws configure
    ```
    * **AWS Access Key ID:** Paste your key.
    * **AWS Secret Access Key:** Paste your secret.
    * **Default region name:** `us-east-1` (or your preferred region).
    * **Default output format:** `json`

---

## 🔐 Step 2: Create SSH Keys

Needed for secure remote connection to the server.

1.  Open your terminal.
2.  Run this command and go through the config process:
    ```bash
    ssh-keygen -t rsa -b 4096
    ```
3.  This creates two files in a hidden folder: `~/.ssh/id_rsa` (private) and `~/.ssh/id_rsa.pub` (public). Terraform will use these automatically.

---

## ⚙️ Step 3: Project Setup

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/xdd1122/redmine_app.git
    cd my-redmine-cloud
    ```

2.  **Create the Environment file:**
    Create a new file named `.env` in the project folder. Paste the following into it and change the passwords:

    ```bash
    # .env
    REDMINE_VERSION=6.0.8
    POSTGRES_VERSION=15-alpine
    REDMINE_PORT=3000

    # Database
    POSTGRES_USER=redmine
    POSTGRES_PASSWORD=your_pass     #change
    POSTGRES_DB=redmine
    REDMINE_DB_POSTGRES=db
    REDMINE_SECRET_KEY_BASE=generate_secret     #change

    # Email setup
    SMTP_HOST=smtp.office365.com
    SMTP_PORT=587
    SMTP_USER=your_user@example.com     #change
    SMTP_PASS=your_user_password    #change
    SMTP_DOMAIN=yourcompany.com     #change
    SMTP_AUTHENTICATION=login
    EMAIL_DELIVERY_METHOD=smtp
    SMTP_ENABLE_STARTTLS_AUTO=true
    ```

---

## 🏗️ Step 4: Building the Image

We need to package the application into a single file to send to AWS.

1.  **Build the Docker Image:**
    (It may take 2-5 minutes.)
    ```bash
    docker build -t redmine-custom:latest .
    ```

2.  **Save the Image to a File:**
    ```bash
    docker save -o redmine-release.tar.gz redmine-custom:latest
    ```

---

## 🚀 Step 5: Deploy to AWS

Now we let Terraform do the heavy lifting.

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

2.  **Review the Plan:**
    ```bash
    terraform plan
    ```

3.  **Apply (Launch):**
    ```bash
    terraform apply
    ```
    * Type `yes` when asked.
    * **Wait:** It will take roughly **5-8 minutes**. Terraform is creating the server, installing Docker on it, uploading your image and starting the app.

4.  **Success:**
    When finished, you will see a green message with your server's IP address:
    ```text
    Apply complete!
    Outputs:
    app_url = "http://10.10.10.10:3000"     #Example
    ```

---

## 🌐 Accessing Your App

1.  Copy the `app_url` from the output and paste it into your browser.
2.  **Default Login:**
    * **User:** `admin`
    * **Password:** `admin`

---

## 🔄 How to Update

If you add a new plugin or change a setting in `.env`:

1.  **Rebuild locally:**
    ```bash
    docker build -t redmine-custom:latest .
    docker save -o redmine-release.tar.gz redmine-custom:latest
    ```

2.  **Redeploy:**
    Tell Terraform to recreate the VM while keeping the static IP and Security Groups intact to avoid noticeable service disruption.
    ```bash
    terraform apply -replace="aws_instance.redmine_vm"
    ```

---

## 🛑 How to Delete Everything

To stop the server and stop paying for AWS resources:

```bash
terraform destroy
```

---

<div id="local-setup"></div>

## 💻 Local Testing (Multipass)

If you don't want to use AWS, or just want to test your configuration for free, you can simulate the **environment** locally using [Multipass](https://multipass.run/). This creates an Ubuntu VM on your computer that acts just like the AWS server.

### 1. Install Multipass
* **MacOS/Windows:** Download the installer from [multipass.run](https://multipass.run/).
* **Linux:** `sudo snap install multipass`

### 2. Prepare the Cloud-Init
The `cloud-init.yaml` file is designed for Terraform (which injects your SSH key). For local use, create a copy that is safe for Multipass:

```bash
# Create a local version
cp cloud-init.yaml cloud-init-local.yaml
```

### 3. Edit *cloud-init-local.yaml*
Open the file and remove the *ssh_authorized_keys* section, as Multipass handles keys differently.

### 4. Launch the VM
```bash
# This installs Docker and sets up permissions automatically
multipass launch jammy --name redmine-local --cpus 2 --mem 2G --disk 10G --cloud-init cloud-init-local.yaml

# 2. Check the status
multipass info redmine-local
```

### 5. Access Redmine
Find the IP of the VM
```bash
multipass list
```
* Copy the IP and open http://IPofVM:3000 in your browser

### 6. Cleanup
```bash
multipass delete redmine-local
multipass purge
```
