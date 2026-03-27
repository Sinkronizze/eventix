# EvenTix - Deployment Guide & Infrastructure Setup

## 1. Pre-Deployment Checklist

### Prerequisites (Must Complete)
- [ ] GitHub organization created and repository initialized
- [ ] Team SSH keys added to GitHub
- [ ] GCash merchant account created (sandbox and production credentials obtained)
- [ ] PostgreSQL knowledge verified among backend team
- [ ] Node.js v18+ and npm v9+ installed locally
- [ ] Git workflow documented (see structure.md)
- [ ] All secrets stored in a secure vault (1Password, GitHub Secrets, etc.)

---

## 2. Database Setup (Supabase PostgreSQL)

### Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Sign up / Log in
3. Create new project:
   - **Project Name:** `eventix-prod`
   - **Database Password:** Generate strong password (save securely)
   - **Region:** Closest to your users (e.g., us-east-1 for North America)

### Step 2: Database Connection Credentials
After project creation, you'll see:
```
PostgreSQL Connection String:
postgresql://postgres:[PASSWORD]@[HOST]:[PORT]/postgres
```

Save these in your secrets manager:
```bash
DB_HOST=db.abc123def456.supabase.co
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=[SECURE_PASSWORD]
DB_URL=postgresql://postgres:[PASSWORD]@db.abc123def456.supabase.co:5432/postgres
```

### Step 3: Run Database Migrations
```bash
# Clone repository locally
git clone https://github.com/your-org/eventix-monorepo.git
cd eventix-monorepo

# Navigate to backend
cd backend

# Install dependencies
npm install

# Set up .env file with Supabase credentials
cat > .env << EOF
DB_URL=postgresql://postgres:[PASSWORD]@db.abc123def456.supabase.co:5432/postgres
NODE_ENV=production
EOF

# Run migrations to create schema tables
npm run migrate:latest

# Seed database with initial data (if needed)
npm run seed:init
```

### Step 4: Verify Database Connection
```bash
npm run test:db-connection
```

**Expected Output:**
```
✅ Database connection successful
✅ Tables created: users, organizations, events, tickets, ...
✅ Row count: organizations=0, users=0, events=0
```

### Step 5: Enable Supabase Features (Dashboard)
1. **Authentication:** Go to Auth → Settings
   - Enable Email/Password
   - Set JWT Secret (auto-generated)
   - Configure email templates (sign-up, password reset)

2. **Real-time:** Go to Replication → Enable
   - This enables real-time syncing for scanner status updates

3. **Backups:** Go to Backups
   - Ensure daily backups enabled
   - Test restore process quarterly

4. **Network Security:**
   - Add IP whitelist for Render backend IPs
   - Add IP whitelist for GitHub Actions runners

---

## 3. Backend Deployment (Render)

### Step 1: Create Render Account & Project
1. Go to [render.com](https://render.com)
2. Sign up with GitHub account for easy integration
3. Create new Web Service:
   - **Name:** `eventix-backend-api`
   - **Environment:** Node.js
   - **Runtime:** Node v18

### Step 2: Connect GitHub Repository
1. Connect your GitHub organization
2. Select branch: `main` (only production-ready code)
3. Configure build command:
   ```bash
   cd backend && npm install && npm run build
   ```

4. Configure start command:
   ```bash
   npm start
   ```

### Step 3: Environment Variables (Render Dashboard)
Go to Environment → Add Variables:

```bash
# Application
NODE_ENV=production
PORT=5000
API_BASE_URL=https://api.eventix.app

# Database
DB_URL=postgresql://postgres:[PASSWORD]@db.abc123def456.supabase.co:5432/postgres

# Authentication
JWT_SECRET=your_super_secret_jwt_key_minimum_32_characters
JWT_EXPIRY=3600
REFRESH_TOKEN_EXPIRY=604800

# GCash Payment Processing
GCASH_API_KEY=your_gcash_api_key
GCASH_MERCHANT_ID=your_gcash_merchant_id
GCASH_WEBHOOK_SECRET=your_gcash_webhook_secret
GCASH_API_VERSION=v2
PLATFORM_FEE_PERCENTAGE=2.5

# Email Service
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=SG.your_sendgrid_api_key
EMAIL_FROM=noreply@eventix.app

# Cryptography (for QR generation)
CRYPTO_SALT=your_random_salt_32_char_minimum
CRYPTO_ALGORITHM=sha256

# Frontend BFF Configuration
FRONTEND_URL=https://eventix.app
CORS_ORIGIN=https://eventix.app

# Logging & Monitoring
LOG_LEVEL=info
SENTRY_DSN=https://your_sentry_id@sentry.io/project_id

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
```

### Step 4: Deploy Backend
```bash
# Push to main branch to trigger deployment
git add .
git commit -m "Deploy: backend API infrastructure"
git push origin main

# Render automatically builds and deploys
# Monitor deployment progress in Render dashboard
```

**Verify Deployment:**
```bash
curl https://api.eventix.app/health

# Expected response:
# {
#   "status": "healthy",
#   "database": "connected",
#   "uptime_seconds": 1234
# }
```

### Step 5: Configure Auto-Deploy & Rollback
1. Go to Render Dashboard → Settings
2. Enable "Auto-Deploy on Push"
3. Set up rollback:
   - If deployment fails, automatically revert to previous version
   - Notify team via Slack webhook

---

## 4. Frontend Deployment (Vercel)

### Step 1: Create Vercel Account
1. Go to [vercel.com](https://vercel.com)
2. Sign up with GitHub account
3. Import GitHub repository

### Step 2: Configure Vercel Project
1. **Project Settings:**
   - **Framework:** Next.js
   - **Root Directory:** `./frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `.next`

2. **Environment Variables:**
   ```bash
   # API Configuration
   NEXT_PUBLIC_API_BASE_URL=https://api.eventix.app
  NEXT_PUBLIC_QR_GENERATION_ENDPOINT=/api/payments/generate-qr
   
   # Feature Flags
   NEXT_PUBLIC_ENABLE_ANALYTICS=true
   NEXT_PUBLIC_ENABLE_ERROR_TRACKING=true
   
   # Domain Configuration
   NEXT_PUBLIC_APP_URL=https://eventix.app
   ```

3. **Domains:**
   - Add custom domain: `eventix.app`
   - Add subdomain: `www.eventix.app` (redirect to apex)
   - Enable SSL (auto-managed by Vercel)

### Step 3: Deploy Frontend
```bash
# Vercel automatically deploys on push to main
git push origin main

# Monitor deployment in Vercel Dashboard
# Visit https://eventix.app to verify
```

**Preview Deployments:**
- Every PR automatically creates a preview deployment
- Useful for testing before merging to main
- Share preview URL with team for review

### Step 4: Performance Optimization (Vercel)
1. **Edge Caching:**
   - Configure Cache-Control headers in `vercel.json`
   - Static pages cached for 1 year
   - Dynamic pages cached for 60 seconds

2. **Image Optimization:**
   - Enable Image Optimization API
   - Automatically serves WebP format
   - Responsive image resizing

3. **Analytics:**
   - Enable Web Analytics on Vercel Dashboard
   - Monitor Core Web Vitals
   - Set up alerts for performance regressions

---

## 5. Environment Variable Management

### Development Environment (.env.local)
```bash
# backend/.env.local
NODE_ENV=development
PORT=5000
DB_URL=postgresql://postgres:password@localhost:5432/eventix_dev
JWT_SECRET=dev_secret_not_for_production
GCASH_API_KEY=your_gcash_dev_api_key
# ... other dev variables
```

### Local Docker Setup (Optional)
```bash
# docker-compose.yml for local development
version: '3.9'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: eventix_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Secrets Management Best Practices
1. **GitHub Secrets:**
   ```bash
   # Store production secrets in GitHub
   Settings → Secrets and variables → Actions
   # Reference in .github/workflows/deploy.yml
   - name: Deploy to Render
     env:
       GCASH_API_KEY: ${{ secrets.GCASH_API_KEY }}
   ```

2. **Never:**
   - Commit `.env` files with real secrets
   - Log secrets in CI/CD logs
   - Share secrets via email or Slack
   - Use same secrets across environments

3. **Rotation:**
   - Rotate API keys every 90 days
   - Store old keys temporarily for client reconnection
   - Invalidate immediately upon compromise

---

## 6. CI/CD Pipeline (GitHub Actions)

### Setup: Create `.github/workflows/deploy.yml`

```yaml
name: Deploy EvenTix

on:
  push:
    branches: [main, staging]
  pull_request:
    branches: [dev, main]

env:
  NODE_VERSION: '18'

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      # Backend Tests
      - name: Backend - Install Dependencies
        working-directory: ./backend
        run: npm install

      - name: Backend - Run Linter
        working-directory: ./backend
        run: npm run lint

      - name: Backend - Run Tests
        working-directory: ./backend
        run: npm test
        env:
          DB_URL: ${{ secrets.TEST_DB_URL }}

      # Frontend Tests
      - name: Frontend - Install Dependencies
        working-directory: ./frontend
        run: npm install

      - name: Frontend - Run Linter
        working-directory: ./frontend
        run: npm run lint

      - name: Frontend - Build
        working-directory: ./frontend
        run: npm run build

  deploy-staging:
    if: github.ref == 'refs/heads/staging' && github.event_name == 'push'
    needs: lint-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy Backend to Render (Staging)
        run: |
          curl -X POST https://api.render.com/deploy/srv-${{ secrets.RENDER_STAGING_SERVICE_ID }}?key=${{ secrets.RENDER_API_KEY }}

      - name: Notify Slack - Staging Deployed
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "✅ EvenTix staging deployed successfully",
              "channel": "#deployments"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}

  deploy-production:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    needs: lint-and-test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy Backend to Render (Production)
        run: |
          curl -X POST https://api.render.com/deploy/srv-${{ secrets.RENDER_PROD_SERVICE_ID }}?key=${{ secrets.RENDER_API_KEY }}

      - name: Deploy Frontend to Vercel (Production)
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          scope: ${{ secrets.VERCEL_ORG_ID }}

      - name: Notify Slack - Production Deployed
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "🚀 EvenTix production deployed successfully by ${{ github.actor }}",
              "channel": "#deployments"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 7. Monitoring & Logging

### Application Monitoring
```bash
# Install Sentry for error tracking
npm install @sentry/node @sentry/tracing

# Configure in backend/src/index.js
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0
});
```

### Log Aggregation
- **Provider:** Render includes built-in logging
- **View logs:** Render Dashboard → Logs
- **Retention:** 7-day retention on free tier

### Performance Monitoring
- **Vercel Analytics:** Monitor Core Web Vitals
- **Backend Metrics:** Render monitors CPU, memory, requests
- **Database Metrics:** Supabase monitors query performance

---

## 8. Backup & Disaster Recovery

### Database Backups
```bash
# Manual backup (run monthly)
pg_dump postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres > backup_$(date +%Y%m%d).sql

# Store backup securely (encrypted)
# Example: Upload to AWS S3 with encryption
aws s3 cp backup_20260327.sql s3://eventix-backups/ --sse AES256
```

### Restore from Backup
```bash
psql postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres < backup_20260327.sql
```

### Disaster Recovery Plan
1. **RTO (Recovery Time Objective):** 1 hour
2. **RPO (Recovery Point Objective):** 24 hours
3. **Backup location:** AWS S3 (separate region from primary)
4. **Restore procedure:** Tested quarterly

---

## 9. Scaling Strategy

### Phase 1 (Current: 0-1000 Users)
- **Frontend:** Vercel free tier (sufficient)
- **Backend:** Render free tier (~100 concurrent connections)
- **Database:** Supabase free tier (500 MB storage)
- **Cost:** ~$15/month (optional add-ons)

### Phase 2 (1000-10000 Users)
- **Frontend:** Vercel Pro ($20/month)
- **Backend:** Render Pro ($7/month for always-on dyno)
- **Database:** Supabase Pro ($25/month)
- **Total:** ~$52/month

### Phase 3 (10000+ Users)
- **Frontend:** Vercel Enterprise custom
- **Backend:** AWS EC2 / Kubernetes (auto-scaling)
- **Database:** AWS RDS PostgreSQL
- **Load Balancer:** AWS ALB
- **CDN:** CloudFront
- **Cost:** $500-5000+/month (depends on usage)

---

## 10. Post-Deployment Verification

### Checklist
- [ ] Health check endpoint responding (`/health`)
- [ ] API endpoints accessible and returning correct data
- [ ] Frontend loads without errors
- [ ] Authentication flow working (login, registration)
- [ ] Payment flow working (test transaction)
- [ ] Emails sending correctly
- [ ] SSL certificates valid and renewed automatically
- [ ] Analytics tracking working
- [ ] Monitoring and alerts active
- [ ] Backups running successfully
- [ ] Team can access dashboards (Vercel, Render, Supabase)

---

## 11. Troubleshooting Common Issues

### Backend Not Starting
```bash
# Check logs
curl https://api.eventix.app/health

# Common causes:
# 1. Missing environment variables
# 2. Database connection failure
# 3. Port already in use
```

### Frontend Build Failing
```bash
# Vercel logs show build error
# Common causes:
# 1. TypeScript errors
# 2. Missing dependencies in package.json
# 3. ESLint / Prettier formatting issues
```

### Database Connection Timeout
```bash
# Verify Supabase is up
# Check IP whitelist includes Render's outbound IPs
# Verify connection string format
```

---

## 12. Maintenance Schedule

| Task | Frequency | Owner |
| :--- | :--- | :--- |
| Review logs and errors | Daily | Zie |
| Test backup restoration | Monthly | Backend Dev |
| Update dependencies | Monthly | Team |
| Security audit | Quarterly | Zie |
| Capacity planning review | Quarterly | Zie |
| Disaster recovery drill | 6 months | Zie |

