# Microsoft Entra Verified ID - Ready-to-Deploy Applications

For a long time, I have been looking at the Microsoft Entra Verified ID feature. It's a powerful technology that allows you to issue verifiable IDs to your colleagues/employees - think of it as a digital employee ID card. This can then be used to verify that the person who, for example, requests access to an application is who they claim to be.

While Microsoft Entra Verified ID is straightforward to set up in the Entra portal, there's one significant challenge: once you have it configured, there's no out-of-the-box solution for users to actually obtain their verified ID credentials or for others to verify them. That's the gap this project fills.

I decided to create a complete web application solution that eliminates the initial development barrier and allows organizations to start experimenting with verifiable credentials right away. This project provides two production-ready web applications that you can fork, deploy, and start using without writing a single line of code.

## Why Two Separate Applications?

Initially, I planned to create a single application, but I encountered a technical challenge that led to a better architectural decision. I wanted to secure the application with Microsoft SSO (Easy Auth) for authenticated credential issuance, but Easy Auth protects the entire application. This created a problem: the verification functionality requires public API callbacks that Easy Auth would block.

After working through this issue, I decided to split the solution into two focused applications:

- **Issue App** - Secured with Easy Auth for employees to obtain verifiable credentials from their authenticated profile
- **Verify App** - Public application for credential verification with optional biometric validation (Face Check)

This separation provides both security and flexibility: employees get credentials through a protected, user-friendly interface, while verification can happen publicly without authentication barriers.

<img width="2003" height="927" alt="image" src="https://github.com/user-attachments/assets/5cbe6427-b7c4-4fdb-a2e2-6a5d4901e28e" />
(Click the picture if needed)

## Prerequisites

Before deploying these applications, you'll need:

1. **Microsoft Entra Verified ID configured** - Complete the setup of Entra Verified ID in your tenant
2. **Azure subscription** - With permissions to create App Service resources
3. **PowerShell execution** - To run the setup script that gathers required configuration values

## Deployment Process

### Step 1: Fork the Repository

Fork this repository to your GitHub account to have your own copy of the code.

### Step 2: Run the Setup Script

Execute the PowerShell script to create the Service Principal and gather configuration values:

```powershell
.\New-VerifiedIdAppRegistration.ps1
```

This script creates the Service Principal needed to read user information from Entra ID and issue verified ID credentials. It will provide you with the Client ID and Client Secret.

You also need to gather these values from your Entra Verified ID configuration:
- **Credential Type** and **Manifest URL** - from Entra admin center → Verified ID → Credentials
- **DID Authority URL** - your domain's DID identifier (formatted as `did:web:yourdomain.com`)

**Important:** Save all these values - you'll need them in the next step.

### Step 3: Deploy to Azure

Click the Deploy to Azure button and provide the configuration values from Step 2:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FChrFrohn%2FEntra-Verified-ID%2Fmain%2Fdeploy%2Fazuredeploy.json)

The deployment will create both applications in a shared App Service Plan in your Azure subscription.

### Step 4: Configure Authentication

**This step is critical - the Issue app won't work without it!**

After deployment, you must enable authentication for the Issue app. This serves two purposes: protecting the application and allowing it to retrieve user information for credential issuance.

1. Navigate to your Issue App in the Azure portal
2. Select **Authentication** from the left navigation
3. Click **Add identity provider** and select **Microsoft**
4. Set **Client secret expiration** to 180 days (or your preferred duration)
5. Enable **Require authentication** 
6. Click **Add** to save the configuration

The first time users access the Issue app, they'll be prompted to consent to the application reading their profile information.

### Step 5: Start Using the Applications

**Issue App:** Employees can now visit the Issue app URL, authenticate with their work account, and obtain verifiable credentials.

**Verify App:** Anyone can visit the Verify app URL to verify credentials without authentication requirements.

## Enhanced Security with Face Check

One of the most exciting features in Entra Verified ID is the ability to perform a face check - comparing a live scan to the photo stored in the credential. This opens up powerful use cases:

- **High-Privilege Access**: Require face verification before users can even request access packages with elevated permissions

The face check feature is what really got me interested in this technology. I believe it can significantly enhance security beyond just the Microsoft ecosystem.

To enable Face Check:
1. Navigate to Azure Portal → Microsoft Entra ID → Verified ID
2. Enable the Face Check add-on (additional charges apply)
3. Configure the confidence threshold to 70% (recommended)

Once enabled, users can select "Enhanced Identity Verification" in the Verify app for biometric comparison during verification.

## Application Architecture

**Issue App Workflow:**
1. Employee authentication via Azure Easy Auth
2. Profile data retrieval from Microsoft Graph
3. Credential issuance request processing
4. QR code generation for Microsoft Authenticator
5. Credential storage in user's digital wallet

**Verify App Workflow:**
1. Public access without authentication
2. Verification method selection (basic or enhanced)
3. QR code presentation for credential holder
4. Real-time verification result display
5. Optional biometric comparison when Face Check is enabled

## Common Issues and Solutions

**Authentication Problems:**
Verify that Microsoft is configured as an identity provider and "Require authentication" is enabled for the Issue app.

**Face Check Not Working:**
Confirm that the Face Check add-on is enabled in Entra and that your credentials contain photo data.

**QR Code Generation Issues:**
Validate all configuration values, particularly the DID authority and credential manifest URLs.

## Project Structure

```
issue-app/          # Employee credential issuance
├── server.js       # Express application with Easy Auth integration
├── package.json    
└── public/index.html

verify-app/         # Public credential verification
├── server.js       # Express application with Face Check support  
├── package.json
└── public/index.html

deploy/
└── azuredeploy.json # Azure Resource Manager template
```

## Cost Considerations

The solution utilizes a shared Azure App Service Plan:
- Single App Service Plan (Basic B1 tier minimum recommended)
- Two App Service instances
- Face Check usage fees (when enabled)

Expected monthly cost: $15-50 depending on usage and selected App Service tier.

## Technical Implementation

The applications are built using Node.js and Express for reliability and ease of maintenance. All credential operations utilize Microsoft's official SDKs to ensure security compliance. QR codes are generated server-side for security, and the architecture avoids local credential data storage by leveraging Microsoft's APIs exclusively.

## Final Words

I hope you find these two applications helpful in getting started with Entra Verified ID. The applications are provided "AS-IS" and are to be used at your discretion. 

You are more than welcome to contribute to the applications or provide feedback via pull requests on GitHub.

## License

MIT License - use and modify as needed for your organization.
