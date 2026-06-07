# Straperr

This is a python flask project to interact between a *arr aplicattions (such as Sonarr, Radarr, Lidarr, etc) and a tracker website.

## Table of Contents

- [Straperr](#straperr)
  - [Table of Contents](#table-of-contents)
  - [Project Structure](#project-structure)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
    - [Cloning the Repository](#cloning-the-repository)
    - [Local Development](#local-development)
    - [Running with Docker](#running-with-docker)
  - [Docker](#docker)
    - [Dockerfile](#dockerfile)
    - [Docker Compose](#docker-compose)
  - [GitHub Actions](#github-actions)
    - [CI/CD Pipeline](#cicd-pipeline)
    - [Deploy to server](#deploy-to-server)
    - [Remove deploy from server](#remove-deploy-from-server)
  - [Secrets Configuration](#secrets-configuration)
  - [Variables Configuration](#variables-configuration)
  - [Documentation](#documentation)
  - [Source Code](#source-code)
  - [Tests](#tests)
---

## Project Structure

```plaintext
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── 0_bug_report.yml                # Template for reporting bugs or issues
│   │   ├── 1_feature_request.yml           # Template for requesting new features
│   │   ├── 2_improvement_request.yml       # Template for suggesting improvements
│   │   ├── 3_performance_issue.yml         # Template for reporting performance issues
│   │   ├── 4_refactor_request.yml          # Template for requesting code refactoring
│   │   ├── 5_documentation_update.yml      # Template for suggesting documentation updates
│   │   ├── 6_security_vulnerability.yml    # Template for reporting security vulnerabilities
│   │   ├── 7_tests_requests.yml            # Template for requesting new tests
│   │   ├── 8_question.yml                  # Template for asking questions
│   │   └── config.yml                      # Configuration file for issue templates
│   ├── workflows/
│   │   ├── cicd.yml                        # CI/CD pipeline configuration using GitHub Actions
│   │   ├── deploy.yml                      # Deploy to server workflow
│   │   └── remove-deploy.yml               # Remove deploy from server workflow
│   ├── dependabot.yml                      # Dependabot configuration for dependency updates
│   └── release.yml                         # Automatic release generation on GitHub
├── docker/
│   ├── .env.example                        # Example environment variables file for Docker
│   ├── Dockerfile                          # Dockerfile to build the project image
│   ├── Dockerfile.local                    # Dockerfile to run the project locally
│   └── compose.yml                         # Docker Compose file to define services and networks
├── docs/
│   ├── VARIABLES.md                        # Documentation about variables needed for integration and deployment
│   ├── SECRETS.md                          # Documentation about secrets needed for deployment
│   └── STYLEGUIDE.md                       # Guidelines for code style and formatting
├── src/
│   ├── .env.example                        # Example environment variables file for the application
│   ├── main.py                             # Main script of the project
│   └── requirements.txt                    # Python dependencies file
├── .dockerignore                           # File to exclude files from Docker context
├── .editorconfig                           # Configuration for code formatting in compatible editors
├── .gitignore                              # File to exclude files and directories from version control
├── AUTHORS                                 # List of authors and contributors to the project
├── CHANGELOG.md (*)                        # History of changes and versions of the project (Created after first main deploy)
├── CODE_OF_CONDUCT.md                      # Code of conduct for project contributors
├── CONTRIBUTING.md                         # Guidelines for contributing to the project
├── GOVERNANCE.md                           # Project governance model and decision-making process
├── LICENSE                                 # Information about the project's license
├── README.md                               # Main documentation of the project
├── SECURITY.md                             # Documentation about project security
└── SUPPORT.md                              # Information on how to get support for the project
```

---

## Prerequisites
Before you begin, make sure you have the following installed in your environment:

- git (obligatory)
- docker (optional, if you want to run the project with Docker)
- docker-compose (optional, if you want to run the project with Docker)
- python (optional, if you want to run the project locally)

## Usage

### Cloning the Repository

To use this template to create a new project, you can clone the repository using the following steps:

1. Click on the "Use this template" button at the top of the repository.
2. Enter the repository name, description, and visibility.
3. Click on the "Create repository from template" button.
4. Clone the newly created repository to your local machine.

```bash
git clone
```

5. Navigate to the cloned repository directory.

```bash
cd <repository-name>
```

6. Start working on your new project!

### Local Development

To develop and test the project locally, follow these steps:

1. Install the dependencies:

```bash
pip install -r src/requirements.txt
```

2. Run the main script:

```bash
python src/main.py
```

### Running with Docker

You can use Docker and Docker Compose to run the project in a container. Ensure Docker and Docker Compose are installed.

1. Navigate to the docker directory, rename the `.env.example` file to `.env`, and adjust the environment variables as needed.

```bash
# Compose environment variables
COMPOSE_PROJECT_NAME=straperr
COMPOSE_FILE=compose.yml

# Network configuration
STRAPERR_PORT=5000
DNS1=8.8.8.8
DNS2=8.8.4.4

# General environment variables
PUID=1000
PGID=1000
TZ=Europe/Madrid
```
- **COMPOSE_PROJECT_NAME**: Name of the Docker Compose project.
- **COMPOSE_FILE**: Docker Compose configuration file.
- **STRAPERR_PORT**: Port to expose the application.
- **DNS1**: Primary DNS server for the container.
- **DNS2**: Secondary DNS server for the container.
- **PUID**: User ID for the container.
- **PGID**: Group ID for the container.
- **TZ**: Timezone for the container.

1. Build and run the services with Docker Compose:

```bash
compose up -d --build
```
This will build the container image according to the Dockerfile and start the services defined in `compose.yml`.

## Docker

### Dockerfile

The `Dockerfile` in the `docker` directory is used to build the Docker image for the project. The file contains instructions to create the image, including the base image, dependencies, and commands to run the application.

The `Dockerfile.local` is used to run the project locally with Docker. This file is used to build the image and run the container locally.

### Docker Compose

The `compose.yml` file in the `docker` directory defines the services and networks for the project using Docker Compose. This file specifies the container image, environment variables, ports, and volumes needed to run the application.

## GitHub Actions

### CI/CD Pipeline

This repository includes a fully automated CI/CD pipeline using `cicd.yml` GitHub Actions. The pipeline is configured to run on each push to the main or development branches and performs the following tasks:

1. **Setup**: Generates the necessary variables for use in the subsequent tasks.
2. **Build**: Builds the Docker image and saves it locally.
3. **Test**: Runs the tests for the application.
4. **Scan**: Scans the Docker image for vulnerabilities using Trivy.
5. **Push**: Pushes the Docker image to the GitHub Container Registry.
6. **Release**: Automatically generates the changelog and creates a new release on GitHub if deploying to `main`.
7. **Merge**: Merges changes from `main` into the `development` branch if a direct push to `main` occurs.
8. **Deploy**: Deploys the application to remote servers using SSH if deploying to `main`.

### Deploy to server

To deploy an specific version of the application to a remote server. You can use the `deploy.yml` workflow. This workflow is triggered by a manual event. Only the `main` branch and tags are allowed to trigger this workflow.

1. **Setup**: Generates the necessary variables for use in the subsequent tasks.
2. **Deploy**: Deploys the application to remote servers using SSH.

### Remove deploy from server

To remove the application from the remote server, you can use the `remove-deploy.yml` workflow. This workflow is triggered by a manual event. Only the `main` branch is allowed to trigger this workflow.

1. **Setup**: Generates the necessary variables for use in the subsequent tasks.
2. **Remove deploy**: Removes the application from remote servers using SSH.

## Secrets Configuration

To properly enable the pipeline and deployment, you need to configure the following secrets in GitHub:

- **SSH_PRIVATE_HOST**: Hostname or IP address of the private SSH server.
- **SSH_PRIVATE_KEY**: Private key for SSH authentication on remote servers.
- **SSH_PRIVATE_PORT**: SSH connection port.
- **SSH_PRIVATE_USER**: SSH user for the server.
- **SSH_PROXY_HOST**: Hostname or IP address of the proxy server.
- **SSH_PROXY_PORT**: Proxy port.
- **SSH_PROXY_USER**: Proxy user.
- **HDOLIMPO_USERNAME**: Username for the HDOLimpo account.
- **HDOLIMPO_PASSWORD**: Password for the HDOLimpo account.
- **SONARR_API_KEY**: API key for the Sonarr API.

More details about these secrets can be found in the [SECRETS.md](docs/SECRETS.md) file.

## Variables Configuration

To properly configure the application, you need to set the following variables in the `.env.example` file:

- **FLASK_ENV**: Flask environment configuration for the application (development, production, testing).
- **FLASK_DEBUG**: Flask debug configuration for the application. Set to `1` for debugging or `0` for production mode.
- **SONARR_API_URL**: URL for the Sonarr API.

Also, you need to set the environment variables for the Docker service:

- **DOCKER_DNS1**: DNS server for the Docker service.
- **DOCKER_DNS2**: Secondary DNS server for the Docker service.
- **DOCKER_NETWORK**: Docker network name for the service.
- **DOCKER_HEALTHCHECK_URL**: Healthcheck URL for the service application.
- **DOCKER_MEMORY_LIMIT**: Memory limit for the Docker service.
- **DOCKER_MEMORY_RESERVATION**: Memory reservation for the Docker service.
- **DOCKER_MEMORY_LIMIT_SELENIUM**: Memory limit for the Docker service running Selenium.
- **DOCKER_MEMORY_RESERVATION_SELENIUM**: Memory reservation for the Docker service running Selenium.
- **DOCKER_SHM_SIZE_SELENIUM**: Shared memory size for the Docker service running Selenium.

More details about these variables can be found in the [VARIABLES.md](docs/VARIABLES.md) file.

## Documentation

The `docs` directory contains additional documentation for the project:

**SECRETS.md**: Provides information on the secrets needed for deployment, including the required environment variables and their configuration.

**STYLEGUIDE.md**: Contains guidelines for code style and formatting, including best practices for writing clean, readable code.

**VARIABLES.md**: Describes the variables needed for integration and deployment, including environment variables for the application and Docker service.

## Source Code

The `src` directory contains the project's source code:

**.env.example**: Example environment variables file for Docker. This file should be renamed to `.env` and adjusted with the necessary variables for the project.

**main.py**: The main script that runs the application. This is where the project's entry point is located.

**requirements.txt**: File listing the Python dependencies needed for the project. This file is used to install the required libraries via pip.

## Tests

The `tests` directory contains the project's test scripts. These tests can be run using the following command:

```bash
pytest src/tests/
```

> [!NOTE]
> Actually there are no tests but they will be added in the future.

The tests are automatically run as part of the CI/CD pipeline to ensure the project's functionality is maintained.
