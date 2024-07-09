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
