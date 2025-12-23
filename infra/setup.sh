#!/bin/bash
# Setup script for Azure Static Website CI/CD
# Run this once to configure GitHub Actions secrets

set -e

echo "🔧 Setting up Azure credentials for GitHub Actions..."

# Variables
APP_NAME="stey-website-github-actions"
RESOURCE_GROUP="rg-stey-website-prod"
LOCATION="eastus2"
GITHUB_ORG="immortality-ai"
GITHUB_REPO="stey-website"

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

# Check if logged in to GitHub CLI
if ! gh auth status &> /dev/null; then
    echo "❌ Please login to GitHub first: gh auth login"
    exit 1
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "📋 Using subscription: $SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
echo "📦 Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION --tags environment=prod project=stey-website || true

# Create Azure AD App Registration for GitHub Actions
echo "🔐 Creating Azure AD App Registration..."
APP_ID=$(az ad app create --display-name $APP_NAME --query appId -o tsv)

# Create Service Principal
echo "👤 Creating Service Principal..."
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# Assign Contributor role to resource group
echo "🔑 Assigning permissions..."
az role assignment create \
    --assignee $APP_ID \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Also need Storage Blob Data Contributor for blob uploads
az role assignment create \
    --assignee $APP_ID \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Create federated credential for GitHub Actions
echo "🔗 Creating federated credential for GitHub Actions..."
TENANT_ID=$(az account show --query tenantId -o tsv)

# Main branch credential
az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
        \"name\": \"github-actions-main\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }"

# Environment credential (for production environment)
az ad app federated-credential create \
    --id $APP_ID \
    --parameters "{
        \"name\": \"github-actions-env-production\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:production\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }"

# Set GitHub secrets
echo "🔒 Setting GitHub secrets..."
gh secret set AZURE_CLIENT_ID --body "$APP_ID" --repo "$GITHUB_ORG/$GITHUB_REPO"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID" --repo "$GITHUB_ORG/$GITHUB_REPO"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID" --repo "$GITHUB_ORG/$GITHUB_REPO"

# Create production environment in GitHub
echo "🌍 Creating production environment..."
gh api repos/$GITHUB_ORG/$GITHUB_REPO/environments/production -X PUT

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Summary:"
echo "   App ID (Client ID): $APP_ID"
echo "   Tenant ID: $TENANT_ID"
echo "   Subscription ID: $SUBSCRIPTION_ID"
echo "   Resource Group: $RESOURCE_GROUP"
echo ""
echo "🚀 Push to main branch to trigger deployment!"
