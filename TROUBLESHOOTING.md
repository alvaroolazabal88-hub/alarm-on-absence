# Troubleshooting log

Every problem hit while building this project, and how it was resolved.
Kept because the fixes are worth more than the code — each one is a mistake
I only had to make once.

---

## `terraform fmt` fails instead of fixing formatting

**Symptom**

```
Error: Missing newline after argument
  region = "us-east-1" }
An argument definition must end with a newline.
```

Both `terraform fmt` and `terraform init` refused to run.

**Cause**

The closing brace was on the same line as an argument. In HCL an argument
must be the last thing on its line.

**Fix**

```hcl
provider "aws" {
  region = "us-east-1"
}
```

**Lesson**

`fmt` formats *valid* HCL — it cannot parse broken syntax to reformat it.
When `fmt` errors, the problem is structural, not cosmetic. Fix the syntax
first, then `fmt`.

---

## `required_providers` rejects an attribute

**Symptom**

```
Error: Invalid required_providers object
  archive = {
required_providers objects can only contain "version", "source" and
"configuration_aliases" attributes.
```

**Cause**

Extra content inside the provider entry.

**Fix**

Each entry holds exactly `source` and `version` (and `configuration_aliases`
if aliasing). Nothing else. Provider *configuration* goes in a `provider`
block, not here.

---

## `backend` block not recognised

**Symptom**

Terraform reported an unexpected block at the top level of the file.

**Cause**

The `backend "s3"` block was written *after* the closing brace of the
`terraform {}` block, at the top level.

**Fix**

`backend` lives *inside* `terraform {}`, next to `required_providers`:

```hcl
terraform {
  required_version  = "..."
  required_providers { ... }

  backend "s3" {
    bucket       = "..."
    key          = "..."
    region       = "..."
    encrypt      = true
    use_lockfile = true
  }
}
```

**Lesson**

Anything that configures Terraform itself — version, providers, backend —
goes inside `terraform {}`. Anything that configures *how to talk to AWS* —
region, default tags — goes in the `provider` block. The `backend` block
also takes only literal values: no variables, no interpolation.

---

## A reference behaved like a literal string

**Symptom**

`terraform plan` showed a versioning/encryption resource being created for
a bucket that did not exist, with the bucket name literally set to
`aws_s3_bucket.s3_backend.id`.

**Cause**

```hcl
bucket = "aws_s3_bucket.s3_backend.id"   # quoted -> literal text
```

Quotes turned a reference into a string. Terraform also lost the implicit
dependency, so it no longer knew to create the bucket first.

**Fix**

```hcl
bucket = aws_s3_bucket.s3_backend.id     # no quotes -> reference
```

**Lesson**

`type.name.attribute` from another resource is never quoted. Quotes are
only for text you invent. References are also how Terraform builds its
dependency graph — the bucket is created alone and first *because* three
other resources reference its `id`.

---

## Python `IndentationError` — blocks in the wrong function

**Symptom**

A `try`/`except` block ended up nested inside `publish_metric` instead of
inside `handler`, and `def handler` sat one indent level in, so Python read
it as a function defined inside another function.

**Cause**

Moving a block between two functions by hand without matching the
indentation of the destination.

**Fix / rule**

- A standalone `def` starts at column 0.
- Its body is exactly 4 spaces in.
- A nested block (`try`, `with`, `if`) inside the body adds 4 more.
- `except` returns to the same indent as its `try`.

Indentation *is* the block structure in Python — there are no braces.

---

## Budget applied cleanly but the alert could go nowhere

**Note, not an error — caught before it bit.**

`aws_budgets_budget` reports success even if
`subscriber_email_addresses` points at an address that does not exist.
Terraform has no way to know the mailbox is real. A typo here produces a
guardian that never fires and never tells you.

**Rule**

Verify every notification target address by eye before applying. This is
the exact failure mode this whole project exists to catch: green status,
nothing delivered.

---

## `git add bootstrap/` staged nothing

**Symptom**

`bootstrap/` and its `.tf` files never appeared in `git status`.

**Cause**

`.gitignore` contained a `bootstrap/` line, ignoring the whole directory —
code included.

**Fix**

Remove that line. The bootstrap *state* is disposable (`*.tfstate` is
already ignored); the bootstrap *code* is not — it is the recipe for the
state backend and has to be in the repo for anyone to reproduce it.

---

## `$` disappeared from a commit message

**Symptom**

```
git commit -m "budget: $10 monthly cap ..."
```

produced a message reading `budget:  monthly cap ...` — the `$10` was gone.

**Cause**

In double quotes the shell expands `$1` as a variable (empty here).

**Fix**

Single quotes:

```
git commit -m 'budget: $10 monthly cap with forecasted alert at 75%'
```
