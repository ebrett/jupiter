# Contributing to Jupiter

Thank you for your interest in contributing to Jupiter! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Follow the setup instructions in the [README](README.md)
4. Create a new branch for your feature or bugfix

## Development Workflow

### Before Making Changes

1. Ensure you have the latest changes from main:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. Run the test suite to ensure everything is working:
   ```bash
   bin/rspec
   bin/rubocop
   ```

### Making Changes

1. Write tests for your changes
2. Implement your feature or bugfix
3. Ensure all tests pass
4. Run the linter and fix any issues

### Code Quality

- Follow the existing code style and conventions
- Write meaningful commit messages
- Keep commits focused and atomic
- Add tests for new functionality
- Update documentation as needed

### Testing

- Write RSpec tests for all new functionality
- Ensure all existing tests continue to pass
- Use FactoryBot for test data
- Follow the existing test patterns

### Code Style

- Use RuboCop with the rails-omakase configuration
- Follow Rails conventions and best practices
- Use ViewComponent for reusable UI components
- Write clear, descriptive variable and method names

## Submitting Changes

1. Push your branch to your fork
2. Create a pull request against the main branch
3. Include a clear description of your changes
4. Reference any related issues

## Reporting Issues

- Use the GitHub issue tracker
- Include clear reproduction steps
- Provide relevant system information
- Include error messages and stack traces

## Questions?

Feel free to open an issue for questions about contributing or development setup.