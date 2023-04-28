# Flux diff Github Action

This Github Action runs `flux diff kustomization` and outputs the result in the github action step summary.

The command `flux diff kustomization` returns all the changes that will be applied at the next flux reconcile. The idea is to run this action when PRs are created having a preview of the differences with the currently deployed resources before merging into `main`.

# Usage

```yaml
TODO
```