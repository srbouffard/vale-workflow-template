# Vale Workflow Template 

This repository provides a standardized, bootstrap-able workflow for linting documentation using [Vale](https://vale.sh/). Its purpose is to make it easy to add this workflow to any project with a single command.

-----

## What It Provides

Running the bootstrap script will add the following to your project:

  * **GitHub Actions Workflow:** A `.github/workflows/docs.yaml` file that automatically runs Vale on every pull request.
  * **Vale Configuration:** A `.vale.ini` file pre-configured to use our central Platform Engineering Vale package, which inherits from the company-wide style guide.
  * **Local Vocabulary:** A `.vale/vocab/Base/accept.txt` file for adding project-specific accepted words.
  * **Makefile Targets:** A standardized `Makefile` and `Makefile.docs` for running checks and managing the Vale environment locally.
  * **.gitignore Rules:** An intelligent set of rules to keep your repository clean by ignoring downloaded Vale packages.

-----

## How to Use

To add this Vale workflow to an existing project, navigate to the root directory of that project and run the following command in your terminal.

**Prerequisites:**

  * You must be in a Git repository.
  * You must be on a feature branch (not `main`).

<!-- end list -->

```bash
bash <(curl -sSL https://raw.githubusercontent.com/srbouffard/vale-workflow-template/main/bootstrap.sh)
```

The script is interactive and will guide you through the setup process.

-----

## The Bootstrap Script

The `bootstrap.sh` script is designed to be safe and intelligent:

  * **✅ Interactive Prompts:** It asks for confirmation before making potentially destructive changes.
  * **Makefile Handling:** If a `Makefile` already exists, it will ask you whether to overwrite it, or save the new targets to `Makefile.tmp` for you to merge manually.
  * **Wordlist Migration:** It can automatically detect an old `.custom_wordlist.txt` file and migrate its contents for you.
  * **Idempotent:** The script can be run multiple times. It will intelligently update the `.gitignore` block without creating duplicate entries.

-----

## Making Changes

To update the workflow for all projects, simply modify the files in **this** repository and commit your changes. The next time a team member runs the bootstrap script in a project, it will pull down the latest versions of the files.
