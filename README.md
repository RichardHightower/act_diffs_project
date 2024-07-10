# Using GitHub Action Workflow Locally

## Introduction

GitHub Actions are powerful tools for automating workflows, but they can sometimes be challenging to debug, and difficult to iterate with. This article will guide you through using the `act` tool to run and test GitHub Actions locally on your laptop, making the development process smoother and more efficient.

## Why Use act for Local GitHub Actions Development:

1. **Speed**: Running actions locally is significantly faster than pushing to GitHub and waiting for the workflow to run.
2. **Debugging**: It's easier to debug issues when you can run the actions in your local environment.
3. **Faster iterations**: You can quickly make changes and rerun the actions without committing and pushing. This also keeps your git repo cleaner. 
4. **Cost-effective**: You're not using up GitHub-hosted runner minutes for testing and debugging.
5. Offline development: You can work on your workflows without an internet connection.

Now, let's walk through the steps of setting up a Python project and using act to test GitHub Actions locally.

- Install `act` with Homebrew
- Set up the project environment using Conda
- Create a project directory
- Install required packages
- Create `requirements.txt`
- Create package structure and main script
- Write unit tests
- Write a GitHub workflow
- Use `act` to run the GitHub workflow locally

## Step 0: Installing act (with Homebrew)

Before we set up our project, let's install act using Homebrew. Homebrew is a package manager for macOS (and Linux), which makes it easy to install and manage various tools and applications.

If you don't have Homebrew installed, you can install it by following the instructions on the official Homebrew website ([https://brew.sh/](https://brew.sh/)).

Once you have Homebrew installed, you can easily install act by running the following command in your terminal:

```bash
brew install act

```

This command will download and install act and its dependencies. After the installation is complete, you can verify that act is installed correctly by running:

```bash
act --version

```

This should display the version of act you've just installed.

Now that we have act installed, let's proceed with setting up our project and using act to run GitHub Actions locally. We assume you already have `conda` and `python` on your development machine. For other operating systems, use the corresponding package manager to install `act`, i.e., for Windows use `chocolatey` , for Linux use `yum` or `apt` or whatever you need. If you can’t find `act` in your package manager of choice, you can build it with the instructions found at the [act project site on github](https://github.com/nektos/act).

```jsx
# Window
choco install act-cli

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

```

On your mac you might have to run:

```jsx
chmod 666 ~/.docker/run/docker.sock

```

## Step 1: Set Up the Project Environment

First, we'll use Conda to create a new environment for our project:

```bash
conda create -n diffs python=3.12
conda activate diffs

```

## Step 2: Make Project Directory

Create a new directory for your project:

```bash
mkdir diffs_project
cd diffs_project

```

## Step 3: Install Required Packages

Install the necessary packages for this project:

```bash
pip install diff-match-patch pytest

```

## Step 4: Create requirements.txt

Generate a requirements.txt file to keep track of dependencies:

```bash
pip freeze > requirements.txt

```

## Step 5: Create Package Structure and Main Script

Create the following directory structure:

```
diffs_project/
│
├── diffs/
│   ├── __init__.py
│   └── core.py
│
├── tests/
│   ├── __init__.py
│   └── test_diffs.py
│
├── main.py
├── requirements.txt
└── .github/
    └── workflows/
        └── test.yml

```

In `diffs/core.py`, add the following content:

```python
from diff_match_patch import diff_match_patch
from typing import List

class Transaction:
    def __init__(self, patches: List[str]) -> None:
        self.patches = patches

class Section:
    def __init__(self, section_type: str, text: str) -> None:
        self.section_type = section_type
        self.text = text

def create_patches(text1: str, text2: str) -> List[str]:
    dmp = diff_match_patch()
    patches = dmp.patch_make(text1, text2)
    return dmp.patch_toText(patches)

def apply_patches(text: str, patches: str) -> str:
    dmp = diff_match_patch()
    patched_text, _ = dmp.patch_apply(dmp.patch_fromText(patches), text)
    return patched_text

def apply_transaction(section: Section, transaction: Transaction) -> Section:
    new_text = apply_patches(section.text, transaction.patches)
    return Section(section.section_type, new_text)

```

Create `main.py` with the following content:

```python
from diffs.core import Transaction, Section, create_patches, apply_transaction
import json

large_block_text_1 = """
Section. 1.
All legislative Powers herein granted shall be vested...
"""

large_block_text_2 = """
in a Congress of the United States, which shall consist of a Senate and House of Representatives.

Section. 2.
The House of Representatives shall be composed of Members chosen every second Year by the People of the several States, and the Electors in each State shall have the Qualifications requisite for Electors of the most numerous Branch of the State Legislature.
"""

# Mock database
database = {
    "Introduction": "This is the original introduction.",
    "Body": large_block_text_1 + "This is the body of the document." + large_block_text_2,
    "Conclusion": "This is the conclusion."
}

if __name__ == '__main__':
    # Example usage
    original_body = database["Body"]

    new_body = large_block_text_1 + "*** This is the updated body. ***" + large_block_text_2
    patches = create_patches(original_body, new_body)
    print("Patches:", patches)

    transaction = Transaction(patches)
    section = Section("Body", original_body)

    updated_section = apply_transaction(section, transaction)
    database[updated_section.section_type] = updated_section.text

    print("\\nUpdated Section:", updated_section.text)
    print("\\nDatabase State:", json.dumps(database, indent=2))

```

Note the example is a bit nonsensical. It is just using one lib for determining differences in text and applying patches. It has nothing to do with `act` or `github action/workflows` per se. 

## Step 6: Write Unit Tests

In `tests/test_diffs.py`, add the following content:

```python
import pytest
from diffs.core import create_patches, apply_patches, Section, Transaction, apply_transaction

def test_create_and_apply_patches():
    text1 = "Hello, world!"
    text2 = "Hello, beautiful world!"
    patches = create_patches(text1, text2)
    assert apply_patches(text1, patches) == text2

def test_apply_transaction():
    original_text = "This is the original text."
    new_text = "This is the updated text."
    patches = create_patches(original_text, new_text)

    section = Section("test_section", original_text)
    transaction = Transaction(patches)

    updated_section = apply_transaction(section, transaction)
    assert updated_section.text == new_text
    assert updated_section.section_type == "test_section"

```

## Step 7: Write a GitHub Workflow

Create a `.github/workflows` directory and add a YAML file for the workflow:

```bash
mkdir -p .github/workflows
touch .github/workflows/test.yml

```

Add the following content to `test.yml`:

```yaml
name: Python Tests

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.12'
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    - name: Test with pytest
      run: |
        pytest tests/

```

## Step 8: Create a git repo

Now that we have our project structure set up, let's initialize it as a Git repository. This step is crucial as GitHub Actions are typically triggered by Git events, and having a Git repository will allow us to test our workflows more realistically.

Navigate to your project directory if you're not already there:

```bash
cd ~/src/diffs_project

```

Initialize the Git repository:

```bash
git init

```

Create a .gitignore file to exclude unnecessary files from version control:

```bash
cat > .gitignore << EOL
**/__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
*.log
**/.DS_Store
.idea
EOL

```

Use `git status` from command line and make sure you don’t have any IDE files, editor files or any files that you don’t want in your git repo. 

Add all the project files to the staging area:

```bash
git add .

```

Commit the files to create the initial commit:

```bash
git commit -m "Initial commit: Set up project structure and basic functionality"

```

You have to have a remote repo set up in GitHub. Go ahead and set up a remote repo using the Web UI or use the github command line as follows

```jsx
gh repo create act_diffs_project --public --source=. --remote=origin --push

```

 If you have a remote repository on GitHub or another Git hosting service, you can add it and push your code:

```bash
git remote add origin <your-remote-repository-url>
git branch -M main
git push -u origin main

```

By turning your project into a Git repository, you're now set up to use Git for version control and to trigger GitHub Actions based on Git events. This setup allows you to test your GitHub Actions workflows locally with act in a way that closely mimics the real GitHub environment.

Remember, while act can run most GitHub Actions locally, some actions might behave differently in a local environment compared to GitHub's servers. Always test your workflows on GitHub as well to ensure full compatibility.

## Step 9: Setting up Docker Desktop

Open Docker Desktop preferences, go to "Resources" > "File Sharing", and make sure that your home directory (or the specific path where your project is located) is included in the list of shared folders.

Restart Docker Desktop: Restarting Docker Desktop can resolve mount-related issues.

## Step 10: Use act to Run GitHub Workflow Locally

First, install act following the instructions in its GitHub repository. Then, run the following command in your project directory:

```bash
act

```

This command will execute the workflow defined in your `test.yml` file locally, allowing you to see the results and debug any issues without pushing to GitHub.

You can change the event after passing the second argument, which specifies the name of your action. In our case, we'll pass "push". This allows you to simulate a push request event, which can be particularly useful for testing workflows that are triggered by git push. 

```jsx
act push
```

You could also handle a “pull_request”. By doing so, you can ensure that your GitHub Actions will behave as expected when a pull request is opened or updated.

Here's an example of how to run the workflow with the "pull_request" event:

```bash
act pull_request

```

This command will execute the workflow as if a pull request event has occurred, enabling you to debug and verify the workflow's behavior before pushing any changes to GitHub. This approach can save you time and help you identify issues early in the development process.

There is a  list available to trigger workflows [on the GitHub action](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows) documentation. To see all the available jobs that you write as a workflow in `.github/workflows`  Use `$ act -l` to list available jobs to define in the `.github/workflows` directory.

## Additional Steps for MacBook Apple Silicon

On a MacBook with Apple silicon you might need to pass the container architecture. 

```jsx
act push --container-architecture linux/amd64
```

Try it with or without and see what works. 

You might run into [mount source path errors](https://github.com/nektos/act/issues/2239) when trying `act` from a MacBook Pro M2 and the act docker image could not read the docker.sock file. To get the docker image to read the docker.sock file add this line

```
--container-daemon-socket -

```

to `~/.actrc`

*The above will disable mounting the docker socket into the job container and should resolve the mount path errors.* 

If you have any issues mounting and you are using a MacBook pro try adding that line to the `~.actrc` file. It worked for me. 

## Conclusion:

Using act to run GitHub Actions locally can significantly streamline your development process. It allows for faster iterations, easier debugging, and more efficient use of resources. By following this guide, you've set up a Python project implementing a diff-patch system with a GitHub Actions workflow and learned how to test it locally using act.

This approach can be scaled to more complex projects and workflows, making your GitHub Actions development process smoother and more efficient. Remember to check the `act` documentation for more advanced usage and options to further customize your local GitHub Actions experience.

By mastering the use of `act`, you'll be able to develop and test your GitHub Actions workflows with greater confidence and efficiency, ultimately leading to more robust and reliable automation for your projects.

# Working with Docker container

Let’s say that your project has a lot of dependencies and it takes a while for your github action workflows to run. To speed things up you decide to put a lot of the dependencies in a base docker image that is stored in the GitHub Container Registry. 

Here are the high-level steps to create a Docker image for your GitHub Actions workflow, store it in GitHub Container Registry ([ghcr.io](http://ghcr.io/)), and update your workflow to use this image:

1. Create a Dockerfile
2. Build the Docker image locally
3. Test the Docker image locally
4. Set up GitHub Container Registry ([ghcr.io](http://ghcr.io/))
5. Push the Docker image to [ghcr.io](http://ghcr.io/)
6. Update the GitHub Actions workflow to use the custom image
7. Test the updated GitHub Actions workflow

Now, let's break down each step:

1. Create a Dockerfile:
    - Create a file named `Dockerfile` in your project root
    - Base it on a Python image
    - Copy requirements.txt and install dependencies
2. Build the Docker image locally:
    - Use `docker build` command to create the image
3. Test the Docker image locally:
    - Run the container
    - Execute tests inside the container
4. Set up GitHub Container Registry:
    - Create a Personal Access Token (PAT) with appropriate permissions
    - Log in to [ghcr.io](http://ghcr.io/) using the PAT
5. Push the Docker image to [ghcr.io](http://ghcr.io/):
    - Tag the image with the [ghcr.io](http://ghcr.io/) repository
    - Push the image to [ghcr.io](http://ghcr.io/)
6. Update the GitHub Actions workflow:
    - Modify the workflow YAML to use the custom Docker image
    - Add steps to log in to [ghcr.io](http://ghcr.io/) and pull the image
7. Test the updated GitHub Actions workflow:
    - Push changes to GitHub
    - Monitor the Actions tab to ensure the workflow runs successfully with the new image

This approach will create a custom Docker image with your dependencies pre-installed, which should significantly speed up your GitHub Actions workflow. The image will be stored in GitHub Container Registry, making it easily accessible for your GitHub Actions.

## Create a Dockerfile

Let's create a Dockerfile for your project. We'll use Python 3.12 as the base image to match your current GitHub Actions workflow. Here's a Dockerfile that should work for your project:

```
# Use Python 3.12 slim image as the base
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code
COPY . .

# Set the command to run pytest
CMD ["pytest", "tests/"]

```

This Dockerfile does the following:

1. Uses the official Python 3.12 slim image as the base. The slim version is smaller and typically sufficient for most Python applications.
2. Sets the working directory in the container to `/app`.
3. Copies the `requirements.txt` file into the container.
4. Installs the Python dependencies listed in `requirements.txt`.
5. Copies the rest of your application code into the container.
6. Sets the default command to run pytest on the tests directory.

To create this Dockerfile:

1. Open a text editor in your project root directory.
2. Copy the above content into the editor.
3. Save the file as `Dockerfile` (no file extension) in your project root.

This Dockerfile assumes that your `requirements.txt` file is in the project root directory. If it's located elsewhere, you'll need to adjust the `COPY` command for `requirements.txt` accordingly.

With this Dockerfile, you're ready to build a Docker image that includes all your project dependencies and is set up to run your tests. This image can be used both locally and in your GitHub Actions workflow.

## Build the Docker image locally

Let’s build the image and read the version from a `version.txt` file. Here's the build script stored in `bin/build_docker_image.sh`:

```bash
#!/bin/bash

# Read version from version.txt
if [ ! -f version.txt ]; then
    echo "version.txt not found. Please create this file with the current version number."
    exit 1
fi

VERSION=$(cat version.txt)

# Set variables
IMAGE_NAME="act_diffs_project"
GITREPO_USERNAME="richardhightower"  # Change this to your GitHub username
PLATFORM="linux/amd64"

# Build the Docker image
echo "Building Docker image version $VERSION..."

# Tag the image for GitHub Container Registry
docker build --platform $PLATFORM -t ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:$VERSION -t ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:latest --push .

echo "Docker image built and pushed as:"
echo "ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:$VERSION"
echo "ghcr.io/$GITREPO_USERNAME/$IMAGE_NAME:latest"

echo "Done!"
```

To use this script:

1. Create a file named `version.txt` in your project root and add your version number to it (e.g., `1.0.0`).
2. Save the script as `build_docker_image.sh` in your project root.
3. Make it executable:
    
    ```bash
    chmod +x bin/build_docker_image.sh
    
    ```
    
4. Run it:
    
    ```bash
    ./bin/build_docker_image.sh
    
    ```
    

This script does the following:

1. Reads the version number from `version.txt`.
2. Sets up variables for the image name and your GitHub username.
3. Builds the Docker image with the version from `version.txt` and 'latest' tag.
4. Tags the image for GitHub Container Registry ([ghcr.io](http://ghcr.io/)).

Before using this script, make sure to:

- Replace `your_github_username` with your actual GitHub username.
- Create a `version.txt` file in your project root with your current version number.

This script provides a simple way to build and tag your Docker image with proper versioning, reading the version from a file. It creates both a version-specific tag and a 'latest' tag, which is a common practice in Docker image management.

## Test the Docker image locally

Let’s create a bash script to run the Docker container and execute tests inside it. We'll name this script `bin/run_tests_in_docker.sh`. This script will use the version from the command line if provided, or read it from `version.txt` if not.

Here's the content of the script:

```bash
#!/bin/bash

# Function to read version from version.txt
read_version_from_file() {
    if [ ! -f version.txt ]; then
        echo "version.txt not found. Please create this file with the current version number."
        exit 1
    fi
    cat version.txt
}

# Check if version is provided as an argument, otherwise read from file
if [ -z "$1" ]; then
    VERSION=$(read_version_from_file)
else
    VERSION=$1
fi

# Set variables
IMAGE_NAME="diffs_project"
GITHUB_USERNAME="revelfire"  # Change this to your GitHub username

# Full image name
FULL_IMAGE_NAME="ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$VERSION"

echo "Running tests for $FULL_IMAGE_NAME"

# Run the container and execute tests
docker run --rm $FULL_IMAGE_NAME pytest tests/

# Check the exit code of the last command
if [ $? -eq 0 ]; then
    echo "Tests passed successfully!"
else
    echo "Tests failed. Please check the output above for details."
fi

```

To use this script:

1. Save it as `run_tests_in_docker.sh` in your project root.
2. Make it executable:
    
    ```bash
    chmod +x bin/run_tests_in_docker.sh
    
    ```
    
3. Run it with or without a version number:
    
    ```bash
    ./bin/run_tests_in_docker.sh
    
    ```
    
    or
    
    ```bash
    ./bin/run_tests_in_docker.sh 1.0.1
    
    ```
    

This script does the following:

1. Defines a function to read the version from `version.txt` if it exists.
2. Checks if a version is provided as an argument. If not, it reads from `version.txt`.
3. Sets up variables for the image name and your GitHub username.
4. Constructs the full image name using the GitHub Container Registry format.
5. Runs the Docker container, executing the pytest command inside it.
6. Checks the exit code of the test run and prints a success or failure message.

Before using this script, make sure to:

- Replace `revelfire` with your actual GitHub username.
- Ensure that `version.txt` exists in your project root if you plan to use it.
- Make sure you've built the Docker image using the `build_docker_image.sh` script we created earlier.

This script allows you to easily run your tests inside the Docker container, ensuring that the tests are executed in an environment that matches your production setup. It's flexible, allowing you to specify a version or use the one from `version.txt`, making it easy to test different versions of your application.

## Set up GitHub Container Registry

Let’s go through the process of setting up GitHub Container Registry ([ghcr.io](http://ghcr.io/)) and logging in using a Personal Access Token (PAT).

1. Create a Personal Access Token (PAT):
    
    a. Go to your GitHub account settings.
    b. Click on "Developer settings" in the left sidebar.
    c. Click on "Personal access tokens" (classic).
    d. Click "Generate new token" (classic).
    e. Give your token a descriptive note (e.g., "GHCR Access").
    f. Select the following scopes:
    
    - `repo` (Full control of private repositories)
    - `write:packages` (Upload packages to GitHub Package Registry)
    - `delete:packages` (Delete packages from GitHub Package Registry)
    - `read:packages` (Download packages from GitHub Package Registry)
    g. Click "Generate token".
    h. Copy the generated token immediately and store it securely. You won't be able to see it again!
2. Log in to [ghcr.io](http://ghcr.io/) using the PAT:
    
    Now that you have your PAT, you can use it to log in to [ghcr.io](http://ghcr.io/). You can do this in two ways:
    
    a. Using Docker CLI:
    
    Run the following command in your terminal:
    
    ```bash
    echo YOUR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
    
    ```
    
    Replace `YOUR_PAT` with the token you just generated and `YOUR_GITHUB_USERNAME` with your GitHub username.
    
    b. Using a credentials file:
    
    Alternatively, you can create a Docker config file with your credentials:
    
    ```bash
    mkdir -p ~/.docker
    echo '{
      "auths": {
        "ghcr.io": {
          "auth": "'$(echo -n YOUR_GITHUB_USERNAME:YOUR_PAT | base64)'"
        }
      }
    }' > ~/.docker/config.json
    
    ```
    
    Again, replace `YOUR_GITHUB_USERNAME` and `YOUR_PAT` with your actual GitHub username and the token you generated.
    
    Add your PAT as a secret key to the repo project under your repo on the GitHub site under Settings→Secrets and variables under the name `GHR_HASH`.
    
3. Verify the login:
    
    You can verify that you've successfully logged in by running:
    
    ```bash
    docker login ghcr.io
    
    ```
    
    If it says "Login Succeeded", you're all set!
    

## Push the Docker image to ghrc.io

After building your Docker image locally, the next step is to push it to GitHub Container Registry ([ghcr.io](http://ghcr.io/)). This allows you to store your image securely and make it easily accessible for your GitHub Actions workflows or other team members.

### Creating the Push Script

We'll create a script called `bin/push_docker_ghcr.sh` to automate the process of tagging and pushing our image. Here's the content of the script:

```bash
#!/bin/bash

# Read version from version.txt
if [ ! -f version.txt ]; then
    echo "version.txt not found. Please create this file with the current version number."
    exit 1
fi

VERSION=$(cat version.txt)

# Set variables
IMAGE_NAME="act_diffs_project"
GITHUB_USERNAME="richardhightower"  # Change this to your GitHub username

# Full image name for ghcr.io
GHCR_IMAGE_NAME="ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME"

# Tag the image for GitHub Container Registry
echo "Tagging image for GitHub Container Registry..."
docker tag $IMAGE_NAME:$VERSION $GHCR_IMAGE_NAME:$VERSION
docker tag $IMAGE_NAME:$VERSION $GHCR_IMAGE_NAME:latest

# Push the image to GitHub Container Registry
echo "Pushing image to GitHub Container Registry..."
docker push $GHCR_IMAGE_NAME:$VERSION
docker push $GHCR_IMAGE_NAME:latest

echo "Image successfully pushed to GitHub Container Registry:"
echo "$GHCR_IMAGE_NAME:$VERSION"
echo "$GHCR_IMAGE_NAME:latest"

```

### Using the Push Script

To use this script:

1. Save it as `push_docker_ghcr.sh` in your project root.
2. Make it executable:
    
    ```bash
    chmod +x bin/push_docker_ghcr.sh
    
    ```
    
3. Ensure you're logged in to GitHub Container Registry (as described in the previous section).
4. Run the script:
    
    ```bash
    ./bin/push_docker_ghcr.sh
    
    ```
    

### What the Script Does

1. **Read Version**: It reads the version number from `version.txt` in your project root.
2. **Set Variables**: It sets up variables for your image name and GitHub username.
3. **Tag Images**: It tags your local image with the [ghcr.io](http://ghcr.io/) repository name, using both the specific version and 'latest' tags.
4. **Push Images**: It pushes both the version-specific and 'latest' tagged images to GitHub Container Registry.

### Important Notes

- Make sure to replace `revelfire` in the script with your actual GitHub username.
- Ensure that you have built the Docker image locally before running this script.
- The script assumes that your local image is named `diffs_project` and tagged with the version number from `version.txt`.

By using this script, you can easily push your Docker image to GitHub Container Registry whenever you're ready to release a new version. This streamlines your workflow and ensures that your latest image is always available for your GitHub Actions or other deployment processes.

## Update the GitHub Actions workflow:

- Modify the workflow YAML to use the custom Docker image
- Add steps to log in to [ghcr.io](http://ghcr.io/) and pull the image

Updated workflow file .github/workflows/test.yml 

```yaml
name: CI

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: read

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Log in to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GHR_HASH }}

    - name: Get version
      id: get_version
      run: echo "VERSION=$(cat version.txt)" >> $GITHUB_OUTPUT

    - name: Get Repo Name
      id: get_repo_name
      run: echo "REPO_NAME=$(echo "${{ github.repository }}" | awk '{print tolower($0)}')" >> $GITHUB_OUTPUT

    - name: Debug
      id: debug
      run: |
        echo "Got this far!!!! ${{ steps.get_version.outputs.VERSION }} ${{ steps.get_repo_name.outputs.REPO_NAME }}"
        echo "Repository: ${{ github.repository }}"
        echo "Version: ${{ steps.get_version.outputs.VERSION }}"
        echo "Full image name: ghcr.io/${{ steps.get_repo_name.outputs.REPO_NAME }}:${{ steps.get_version.outputs.VERSION }}"

    - name: Pull Docker container
      run: |
        docker pull --platform linux/amd64 ghcr.io/${{ steps.get_repo_name.outputs.REPO_NAME }}:${{ steps.get_version.outputs.VERSION }}

    - name: Run tests in Docker container
      run: |
        docker run --rm --platform linux/amd64 ghcr.io/${{ steps.get_repo_name.outputs.REPO_NAME }}:${{ steps.get_version.outputs.VERSION }} pytest tests/

```

This GitHub Actions workflow, named "CI" (Continuous Integration), is triggered on every push to the repository. Here's a breakdown of what it does:

1. Sets up the job:
    - Runs on the latest Ubuntu runner
    - Sets permissions for contents (read) and packages (read)
2. Checks out the repository:
    - Uses actions/checkout@v4 to clone the repository into the runner
3. Logs in to GitHub Container Registry (GHCR):
    - Uses docker/login-action@v3
    - Authenticates using the GitHub actor (current user) and a secret GHR_HASH
4. Gets the version:
    - Reads the version from a file named version.txt
    - Stores it as an output variable named VERSION
5. Gets the repository name:
    - Extracts the repository name from github.repository
    - Converts it to lowercase
    - Stores it as an output variable named REPO_NAME
6. Debugging step:
    - Prints out version, repository name, and full image name for verification
7. Pulls the Docker container:
    - Uses docker pull to download the image from GHCR
    - Specifies the platform as linux/amd64
    - Uses the version and repository name obtained earlier
8. Runs tests in the Docker container:
    - Uses docker run to start a container from the pulled image
    - Specifies the platform as linux/amd64
    - Runs pytest tests/ inside the container

This workflow essentially sets up the environment, pulls a specific version of a Docker image from GitHub Container Registry, and then runs tests inside that Docker container. It's designed to ensure that the tests are run in a consistent environment (the Docker container) regardless of where the workflow is executed.