# Deployment Guide

This guide covers deploying Jupiter to production environments.

## Fly.io Deployment

Jupiter is configured for deployment on Fly.io with PostgreSQL and Redis.

### Prerequisites

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Authenticate with Fly**
   ```bash
   fly auth login
   ```

### Initial Deployment

1. **Deploy the application**
   ```bash
   fly deploy
   ```

2. **Set required secrets**
   ```bash
   # Rails configuration
   fly secrets set SECRET_KEY_BASE="$(openssl rand -hex 64)"
   fly secrets set RAILS_MASTER_KEY="$(cat config/master.key)"
   
   # NationBuilder OAuth (required)
   fly secrets set NATIONBUILDER_CLIENT_ID="your_client_id"
   fly secrets set NATIONBUILDER_CLIENT_SECRET="your_client_secret"
   fly secrets set NATIONBUILDER_REDIRECT_URI="https://your-app-name.fly.dev/auth/nationbuilder/callback"
   fly secrets set NATIONBUILDER_NATION_SLUG="your_nation_slug"
   
   # External APIs (optional)
   fly secrets set PERPLEXITY_API_KEY="your_perplexity_api_key"
   ```

3. **Run database migrations**
   ```bash
   fly ssh console -C "bin/rails db:migrate"
   ```

4. **Seed initial data**
   ```bash
   fly ssh console -C "bin/rails db:seed"
   ```

### Updating the Application

```bash
# Deploy new changes
fly deploy

# Run migrations if needed
fly ssh console -C "bin/rails db:migrate"

# Check application status
fly status
```

## Environment Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Rails secret key | Generated with `openssl rand -hex 64` |
| `RAILS_MASTER_KEY` | Rails credentials key | Content of `config/master.key` |
| `DATABASE_URL` | PostgreSQL connection | Auto-configured by Fly |
| `REDIS_URL` | Redis connection | Auto-configured by Fly |

### NationBuilder OAuth Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NATIONBUILDER_CLIENT_ID` | OAuth client ID | Yes |
| `NATIONBUILDER_CLIENT_SECRET` | OAuth client secret | Yes |
| `NATIONBUILDER_REDIRECT_URI` | OAuth callback URL | Yes |
| `NATIONBUILDER_NATION_SLUG` | Nation subdomain | Yes |

See [OAuth documentation](OAUTH.md) for detailed setup instructions.

## Database Management

### Accessing the Database

```bash
# Connect to database console
fly ssh console -C "bin/rails db:console"

# Run Rails console
fly ssh console -C "bin/rails console"

# Run specific commands
fly ssh console -C "bin/rails db:migrate"
```

### Backups

Fly.io automatically backs up PostgreSQL databases. To create manual backups:

```bash
# Create backup
fly postgres backup create

# List backups
fly postgres backup list

# Restore from backup
fly postgres backup restore <backup-id>
```

## Monitoring and Logs

### Application Logs

```bash
# View recent logs
fly logs

# Follow logs in real-time
fly logs -f

# Filter logs by instance
fly logs --instance <instance-id>
```

### Health Checks

Jupiter includes health check endpoints:

- **Application health**: `https://your-app.fly.dev/health`
- **OAuth status**: `https://your-app.fly.dev/system/oauth_status`

### Performance Monitoring

Monitor key metrics:

```bash
# Check resource usage
fly status

# View metrics dashboard
fly dashboard

# SSH into running instance
fly ssh console
```

## SSL and Security

### HTTPS Configuration

Fly.io automatically provides SSL certificates. Ensure:

- All OAuth redirect URIs use HTTPS
- Force SSL is enabled in production (configured in `config/environments/production.rb`)
- Security headers are properly configured

### Security Best Practices

- Regularly rotate secret keys
- Monitor for security vulnerabilities with Brakeman
- Keep dependencies updated
- Review audit logs regularly

## Troubleshooting

### Common Deployment Issues

**Database connection errors:**
```bash
# Check database status
fly postgres status

# Restart database if needed
fly postgres restart
```

**Memory issues:**
```bash
# Check resource usage
fly status

# Scale up memory if needed
fly scale memory 1024
```

**OAuth configuration errors:**
- Verify all NationBuilder credentials are set correctly
- Check redirect URI matches exactly
- Ensure nation slug is correct

### Debug Commands

```bash
# Check environment variables
fly secrets list

# View application configuration
fly ssh console -C "bin/rails runner 'puts Rails.application.config.inspect'"

# Test OAuth connection
fly ssh console -C "bin/rails runner 'puts NationbuilderApiClient.new.test_connection'"
```

### Scaling

```bash
# Scale to multiple instances
fly scale count 2

# Scale memory
fly scale memory 1024

# Scale specific machine type
fly scale vm shared-cpu-2x
```

## Maintenance

### Regular Tasks

1. **Update dependencies**
   ```bash
   bundle update
   yarn upgrade
   ```

2. **Run security scans**
   ```bash
   bin/brakeman
   bundle audit
   ```

3. **Monitor logs for errors**
   ```bash
   fly logs | grep ERROR
   ```

4. **Check OAuth health**
   - Visit `/system/oauth_status`
   - Monitor token refresh success rates

### Backup Strategy

- Database: Automated daily backups via Fly.io
- Application secrets: Store securely in password manager
- Configuration: Version controlled in Git repository