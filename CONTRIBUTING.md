# Contributing

Thank you for your interest in contributing to this Helm chart repository. This document describes the expected development, documentation, and review standards.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion for improvement:

1. Check if the issue already exists in the [Issues](https://github.com/ducthangqd1998/charts/issues) section.
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Helm/Kubernetes versions
   - Chart version being used

### Suggesting New Charts

If you have a tool or infrastructure component that needs a Helm chart:

1. Open an issue with the "chart request" label
2. Provide information about:
   - The tool, application, or infrastructure resource name and purpose
   - Why it needs a Helm chart
   - Link to the original project
   - Any existing deployment methods
   - Your use case

### Code Contributions

#### Prerequisites

- Git
- Helm 3.0+
- Kubernetes cluster for testing
- Basic understanding of Kubernetes and Helm

#### Development Process

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/charts.git
   cd charts
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow the [Chart Standards](#chart-standards) below
   - Test your changes thoroughly
   - Update documentation

4. **Test Your Changes**
   ```bash
   # Lint the chart
   helm lint ./charts/your-chart

   # Test templates
   helm template test-release ./charts/your-chart

   # Test installation (if possible)
   helm install test-release ./charts/your-chart --dry-run
   ```

5. **Commit and Push**
   ```bash
   git add .
   git commit -m "feat: add new chart for awesome-tool"
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Provide clear description of changes
   - Reference any related issues
   - Include testing instructions

## Chart Standards

All charts must follow these standards:

### Required Files

At minimum, a chart should include:

```text
charts/chart-name/
|-- Chart.yaml
|-- values.yaml
|-- README.md
|-- templates/
|   |-- _helpers.tpl
|   `-- NOTES.txt
`-- examples/
    `-- example-values.yaml
```

Additional templates should match the chart type. Application charts commonly include `Deployment`, `Service`, `Ingress`, `ServiceAccount`, and autoscaling templates. Infrastructure charts may instead render CRDs or control-plane resources such as Gateway API resources.

### Chart.yaml Requirements

```yaml
apiVersion: v2
name: chart-name
description: A clear description of what this chart does
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - relevant
  - keywords
home: https://github.com/ducthangqd1998/charts
sources:
  - https://github.com/original-project/repo
  - https://github.com/ducthangqd1998/charts
maintainers:
  - name: maintainer-name
```

### values.yaml Standards

- Use descriptive comments
- Provide sensible defaults
- Follow Kubernetes naming conventions
- Include all configurable options
- Use consistent formatting

### Template Standards

- Use `_helpers.tpl` for common template functions
- Include resource limits/requests configuration for workload charts
- Support security contexts for workload charts
- Include liveness/readiness probes for workload charts
- Support ingress or Gateway API configuration when the chart exposes HTTP traffic
- Use consistent labeling

### Required Labels

All resources must include these labels:
```yaml
labels:
  helm.sh/chart: {{ include "chart.chart" . }}
  app.kubernetes.io/name: {{ include "chart.name" . }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
```

Workload charts should also include `app.kubernetes.io/version` when `appVersion` is meaningful for the deployed application.

### Documentation Requirements

#### README.md Must Include:

1. Overview of what the chart manages.
2. Prerequisites.
3. Installation instructions from the Helm repository and from source.
4. Configuration tables or documented values.
5. Usage examples.
6. Rendered resources or architecture notes when useful.
7. Troubleshooting notes.

Public examples should use generic domains, namespaces, service names, and labels. Do not publish organization-specific hostnames, account IDs, cluster names, or internal application names.

#### NOTES.txt Must Include:

1. How to access the application
2. Next steps after installation
3. Important configuration notes

### Testing Requirements

Every chart should include:

1. **Lint validation**: `helm lint` passes
2. **Template validation**: `helm template` works with default values and documented examples
3. **Schema validation**: `values.schema.json` when practical for non-trivial charts
4. **Installation test**: Can be installed with default values when the chart supports default installation
5. **Functional test**: Basic functionality verification when practical

## Code Style

### YAML Formatting

- Use 2 spaces for indentation
- No trailing whitespaces
- Unix line endings (LF)
- Files should end with a newline

### Template Formatting

- Use meaningful variable names
- Include comments for complex logic
- Keep templates readable and maintainable

### Commit Message Format

Use conventional commits:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature/chart
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

Examples:
```
feat(metrics-accumulator): add Helm chart for metrics-accumulator
fix(metrics-accumulator): correct service port configuration
docs(README): update installation instructions
```

## Review Process

1. **Automated Checks**: PRs must pass all automated tests
2. **Manual Review**: Maintainer reviews for:
   - Code quality and standards compliance
   - Documentation completeness
   - Security considerations
   - Best practices adherence
3. **Testing**: Verification that the chart works as expected
4. **Approval**: Approved PRs are merged to main branch

## Release Process

Charts are released when:
1. New chart is added
2. Significant updates to existing charts
3. Bug fixes that affect functionality

Version bumping follows semantic versioning:
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes, backward compatible

## Getting Help

If you need help:

1. Check existing [Issues](https://github.com/ducthangqd1998/charts/issues)
2. Review chart examples in the repository
3. Create a new issue with questions
4. Reach out to maintainers

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow
- Follow the project's standards and guidelines

Thank you for contributing.
