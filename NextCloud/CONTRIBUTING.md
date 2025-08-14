# Contributing to Nextcloud AIO Automated Installer

Thank you for your interest in contributing to this project! This guide will help you get started.

## 🛠 Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nextcloud-aio-automated-installer.git
   cd nextcloud-aio-automated-installer
   ```
3. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## 📝 Coding Standards

### Shell Script Standards
- Use `#!/bin/bash` shebang
- Use 4-space indentation
- Use descriptive variable names in `UPPER_CASE` for constants
- Use `lower_case` for function names and local variables
- Include comprehensive error handling
- Add colored output for better user experience
- Include logging for debugging purposes

### Function Structure
```bash
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Validation
    if [[ -z "$param1" ]]; then
        log_error "Parameter 1 is required"
        return 1
    fi
    
    # Function logic
    log_info "Doing something with $param1"
    
    # Return appropriate exit code
    return 0
}
```

### Error Handling
Always include proper error handling:
```bash
if ! command_that_might_fail; then
    log_error "Command failed"
    return 1
fi
```

## 🧪 Testing

### Manual Testing
- Test on multiple Linux distributions when possible
- Test with and without NFS configuration
- Test both interactive and command-line modes
- Verify all error conditions are handled gracefully

### Testing Checklist
- [ ] Script runs without errors on Ubuntu 24.04
- [ ] Script handles missing dependencies gracefully
- [ ] All user prompts work correctly
- [ ] Error messages are clear and helpful
- [ ] Logging output is appropriate
- [ ] Script can be run multiple times safely

## 🚀 Submitting Changes

1. **Test your changes** thoroughly
2. **Update documentation** if needed
3. **Commit your changes** with clear messages:
   ```bash
   git commit -m "Add feature: description of what you added"
   ```
4. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request** on GitHub

### Pull Request Guidelines
- Provide a clear description of the changes
- Reference any related issues
- Include testing notes
- Update documentation if necessary

## 🐛 Reporting Issues

When reporting bugs, please include:
- Your Linux distribution and version
- Docker version (if applicable)
- Complete error messages
- Steps to reproduce the issue
- Expected vs actual behavior

## 💡 Feature Requests

We welcome feature requests! Please:
- Check if a similar request already exists
- Provide clear use case descriptions
- Explain how the feature would benefit users
- Consider offering to implement it yourself

## 📋 Areas for Contribution

### High Priority
- **SSL/Let's Encrypt integration** - Automated SSL certificate setup
- **Backup automation** - Automated backup scripts for Nextcloud data
- **Update scripts** - Automated update mechanisms for containers
- **Health monitoring** - System health check scripts

### Medium Priority
- **Additional distribution support** - More Linux distributions
- **Configuration templates** - Pre-built configuration options
- **Monitoring integration** - Prometheus/Grafana setup scripts
- **Security hardening** - Additional security measures

### Low Priority
- **GUI installer** - Web-based installation interface
- **Docker Swarm support** - Multi-node deployment scripts
- **Advanced networking** - Custom network configurations
- **Plugin system** - Modular plugin architecture

## 🏗 Code Structure

```
nextcloud-aio-automated-installer/
├── README.md                     # Main documentation
├── CONTRIBUTING.md               # This file
├── LICENSE                       # MIT License
├── scripts/                      # All installation scripts
│   ├── install-complete-stack.sh    # Master installer
│   ├── install-docker-complete.sh   # Docker installation
│   ├── install-nextcloud-aio.sh     # Nextcloud AIO setup
│   ├── setup-nfs.sh                 # NFS client configuration
│   ├── update-system.sh             # System updates
│   ├── run-nextcloud-aio.sh         # Docker group wrapper
│   └── activate-docker-group.sh     # Group activation utility
├── examples/                     # Example configurations
│   └── docker-compose-example.yml   # Docker Compose template
└── .gitignore                    # Git ignore rules
```

## 🎯 Best Practices

### Script Development
1. **Start small** - Begin with simple, focused changes
2. **Test thoroughly** - Always test on clean systems
3. **Document changes** - Update README and comments
4. **Follow patterns** - Use existing code style and patterns
5. **Handle errors** - Always include proper error handling

### Git Workflow
1. **Keep commits small** - One logical change per commit
2. **Write clear messages** - Descriptive commit messages
3. **Update documentation** - Keep docs in sync with code
4. **Test before pushing** - Ensure everything works

## ❓ Questions?

If you have questions about contributing:
- Open an issue with the "question" label
- Check existing issues and discussions
- Review the code and documentation

## 🙏 Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- Release notes for significant contributions
- Project documentation where appropriate

Thank you for contributing to make this project better! 🎉
