# git_sync

Source: `update_scripts/global_scripts/04_utils/git_sync.R`

## Functions

**Function List:**
- [run_git_cmd](#run-git-cmd)
- [git_pull](#git-pull)
- [git_status](#git-status)
- [git_add_all](#git-add-all)
- [git_commit](#git-commit)
- [git_push](#git-push)
- [git_sync](#git-sync)

### run_git_cmd

Run a git command and print its output


## Parameters

- **cmd The git command to run**
- **repo_path The path to the git repository**

## Return Value

The result of the command

---


### git_pull

Pull changes from the remote repository


## Parameters

- **repo_path The path to the git repository**
- **remote The name of the remote repository**
- **branch The branch to pull from**

## Return Value

The result of the pull command

---


### git_status

Get the git status


## Parameters

- **repo_path The path to the git repository**

## Return Value

The result of the status command

---


### git_add_all

Stage all changes


## Parameters

- **repo_path The path to the git repository**

## Return Value

The result of the add command

---


### git_commit

Commit changes


## Parameters

- **message The commit message**
- **repo_path The path to the git repository**

## Return Value

The result of the commit command

---


### git_push

Push changes to the remote repository


## Parameters

- **repo_path The path to the git repository**
- **remote The name of the remote repository**
- **branch The branch to push to**

## Return Value

The result of the push command

---


### git_sync

Full sync workflow: pull, add changes, commit with message, and push


## Parameters

- **commit_message The commit message for staged changes**
- **repo_path The path to the git repository**
- **remote The name of the remote repository**
- **branch The branch to work with**
- **skip_pull Set to TRUE to skip pulling changes**

## Return Value

Invisibly returns TRUE if successful

---

