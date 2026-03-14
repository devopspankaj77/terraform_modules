# Resource Controls Sheet – Prod vs Non-Prod

Comprehensive baseline controls for all resources in this Terraform project. Use for compliance, audit, and environment parity.

**Columns:** Pillar | Type | Control | Prod | Non-Prod | Reason | **Implemented** | **Remarks**

**Implemented** = whether the control is implemented in this repo’s **modules** or **environment** (dev/prod) files: **Yes** (in module/env), **Partial** (partially or env-only), **No** (not in repo; e.g. Azure default, policy, or manual). **Remarks** = what is required to implement if not done (— when done).

*Implementation status (current): Optional baseline controls are implemented in modules and enableable via tfvars—e.g. RG lock, VNet subnets_allow_private_endpoint, storage soft delete/network_rules/delete lock, VM boot diagnostics/availability_zone/encryption_at_host, Key Vault network_acls/delete lock, SQL Azure AD admin/short_term_retention_days, App Service https_only/identity/always_on, RSV delete lock. See OPTIONAL_SECURITY_TFVARS.md and dev/prod tfvars REMARKs.*

---

## Implementation summary: are all controls implemented?

**No. Not all controls in this sheet are implemented in the project.** The sheet is an audit: each row has **Implemented** (Yes / Partial / No / Env) and **Remarks**. Summary:

| Status | Meaning | Approx. count |
|--------|--------|----------------|
| **Yes** | Implemented in module or env (dev/prod) | ~95 |
| **Partial** | Partially done or env-only; see Remarks in table | ~25 |
| **No** | Not in repo; implement per Remarks or accept risk | ~45 |
| **Env** | Design/tfvars (naming, tags, SKU choices) | ~15 |

**Implemented in project:** RG (tags, lock), VNet (NSG, PE subnet policies via subnets_allow_private_endpoint, nsg_rules), VM (AAD, SSH-only, MI, boot diagnostics, availability_zone, encryption_at_host), Storage (TLS, versioning, soft delete, network_rules, lock, no public access), Key Vault (RBAC, soft delete, purge, no public access, network_acls, lock), SQL (TLS, firewall, Azure AD admin, short_term_retention_days), Redis (non-SSL off, TLS 1.2), App Service (HTTPS, identity, always_on, FTPS off), RSV (soft delete, lock), PE + private DNS, Bastion (SKU, copy_paste/file_copy/tunneling), ACR (admin off, public_network_access), AKS (Azure RBAC, network_plugin), APIM (identity, VNet), NAT Gateway, Public IP (Standard, static), NSG (explicit allow, jump_rdp/ssh_source_cidr).

**Not implemented (No):** Budget alerts, DDoS, VNet/NSG/Storage/KV/SQL/MySQL/Redis/Bastion/App Service/Function/Logic/APIM/AKS/ACR/LA/App Insights/RSV **diagnostic logs to Log Analytics**; VM disk encryption, JIT, VM insights; Storage/ACR lifecycle and CMK; Key Vault CMK and alerts; SQL TDE, LTR, zone redundancy; MySQL geo-backup, HA, auto-grow, maintenance; Redis cluster, maintenance; App Service/Function access restriction, slots, App Insights link; AKS private cluster, OIDC, zones, container insights; ACR content trust, vulnerability scan, geo-replication, soft delete; LA/App Insights CMK, daily cap, sampling; RSV RBAC for backup, immutability, replication; Terraform state RBAC, PE, GZRS, lock; RBAC review, no Owner for automation. See **Remarks** column in each section below for what to do.

---

## Resource Group

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Governance | Mandatory | Naming convention (e.g. rg-&lt;org&gt;-&lt;env&gt;-&lt;workload&gt;) | Required | Required | Consistency, cost tracking | Env (tfvars) | — |
| Governance | Mandatory | Mandatory tags (Created By, Created Date, Environment, Requester, Ticket, Project) | Required | Required | Audit, chargeback | Yes (main.tf common_tags) | — |
| Governance | Mandatory | Additional tags (Owner, Cost Center, Data Classification) | Required | Recommended | FinOps, compliance | Yes (additional_tags tfvars) | — |
| Governance | Optional | Delete lock (CanNotDelete) | Recommended | Optional | Prevent accidental deletion | Yes (resource-group module create_lock, lock_level; optional via tfvars) | — |
| Governance | Mandatory | No resources without tags | Required | Required | Enforce via policy | Yes (tags passed to modules) | — |
| Cost Optimization | Mandatory | Single RG per env/workload or per application boundary | Required | Required | Clear ownership, chargeback | Env (design) | — |
| Cost Optimization | Optional | Budget alerts on RG | Required | Recommended | Cost visibility | No | Create budget + alerts in Azure Cost Management or separate Terraform |
| Operational Excellence | Mandatory | Document RG purpose in naming or tag | Required | Recommended | Discoverability | Partial (naming/tags in tfvars) | Add tag e.g. Purpose/Description in additional_tags if needed |

---

## Virtual Network (VNet)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | NSG on all subnets (except AzureBastionSubnet) | Required | Required | Network segmentation | Yes (vnet module create_nsg, nsg_per_subnet) | — |
| Security | Mandatory | No 0.0.0.0/0 for management ports (RDP 3389, SSH 22) in NSG | Required | Recommended | Limit exposure | Partial (env: jump_rdp_source_cidr, jump_ssh_source_cidr) | Set TF_VAR_jump_rdp_source_cidr / jump_ssh_source_cidr to VPN/bastion CIDR in prod |
| Security | Mandatory | Private endpoint subnet with network policies disabled | Required | Recommended | PaaS private connectivity | Yes (vnet module PE subnet private_endpoint_network_policies = Disabled) | — |
| Security | Mandatory | Deny-by-default: explicit allow rules only | Required | Required | Least privilege | Yes (nsg_rules are explicit allow) | — |
| Security | Mandatory | Restrict inter-subnet traffic where not needed | Recommended | Optional | Micro-segmentation | Partial (env-defined nsg_rules) | Define nsg_rules per subnet in tfvars with minimal source/dest CIDRs |
| Security | Optional | DDoS Protection Standard (optional for critical) | Recommended | Optional | Availability | No | Enable DDoS Plan and associate to VNet via separate Terraform or portal |
| Security | Mandatory | No overlapping address spaces across envs | Required | Required | No routing conflicts | Env (tfvars design) | — |
| Reliability | Mandatory | Non-overlapping CIDR within subscription | Required | Required | Peering, connectivity | Env (tfvars) | — |
| Reliability | Optional | Multiple subnets for tier separation (app, data, mgmt) | Required | Recommended | Isolation | Yes (subnets map in tfvars) | — |
| Reliability | Optional | Availability zones for critical subnets where supported | Required | Optional | HA | No | Add zone support in vnet module if provider supports it |
| Operational Excellence | Mandatory | NSG flow logs to Log Analytics | Required | Recommended | Audit trail, troubleshooting | No | Add azurerm_network_watcher_flow_log + diagnostic to LA workspace |
| Operational Excellence | Mandatory | Diagnostic logs for VNet (if supported) | Required | Optional | Audit | No | Configure VNet diagnostic setting to Log Analytics |
| Governance | Mandatory | Mandatory tags on VNet and subnets | Required | Required | Audit | Yes (tags passed to vnet module) | — |
| Governance | Mandatory | Naming convention (vnet-&lt;org&gt;-&lt;env&gt;-&lt;region&gt;) | Required | Required | Consistency | Env (tfvars) | — |
| Cost Optimization | Optional | Right-size address space (no over-provisioning) | Recommended | Recommended | IP conservation | Env (tfvars) | — |

---

## Virtual Machine (VM)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Public IP only when required (e.g. jump box) | No public IP for app VMs | Same | Reduce attack surface | Yes (vm module create_public_ip) | — |
| Security | Mandatory | Restrict RDP/SSH source (jump) to VPN or bastion CIDR | Required | Recommended | Prevent open management | Partial (env: jump_rdp_source_cidr, jump_ssh_source_cidr) | Set jump_rdp_source_cidr / jump_ssh_source_cidr in prod tfvars or TF_VAR |
| Security | Mandatory | Azure AD login extension (AADLoginForLinux / AADLoginForWindows) | Required | Required | Identity-based access | Yes (vm module AAD extension) | — |
| Security | Mandatory | Linux: SSH only, password authentication disabled | Required | Required | Strong authentication | Yes (vm module disable_password_authentication = true) | — |
| Security | Mandatory | Windows: complex password policy (Azure default); prefer Azure AD login | Required | Required | Strong authentication | Partial (Azure default; AAD in module) | — |
| Security | Mandatory | System-assigned managed identity enabled | Required | Required | Key Vault / storage / ACR access | Yes (vm module identity block) | — |
| Security | Mandatory | Virtual Machine Administrator Login (or User Login) via RBAC | Required | Required | Least privilege | Yes (main.tf role assignment) | — |
| Security | Optional | Disk encryption (Azure Disk Encryption or PMK/CMK) | Required | Recommended | Data at rest | No | Add disk encryption extension or CMK in vm module / separate config |
| Security | Mandatory | No unencrypted OS or data disks | Required | Required | Azure encrypts by default; CMK for compliance | Partial (Azure default) | For CMK: add encryption_at_rest in module |
| Security | Optional | JIT VM access (Azure Defender) | Recommended | Optional | Reduce exposure | No | Enable in Defender for Cloud; not in Terraform |
| Reliability | Mandatory | Managed disk only (no unmanaged) | Required | Required | Durability, backup, encryption | Yes (Azure default in module) | — |
| Reliability | Mandatory | Premium SSD for prod workloads where SLA required | Required | Optional | Performance, SLA | Env (vm size / os_disk_type in tfvars) | Set os_disk_type = Premium_LRS and size in prod tfvars |
| Reliability | Optional | Availability set or availability zone for critical VMs | Required | Optional | HA | Yes (vm module availability_zone; optional via tfvars) | — |
| Reliability | Optional | Multiple NICs for isolation (optional) | Optional | Optional | Network isolation | No | Not in current vm module |
| Operational Excellence | Mandatory | Boot diagnostics to storage or Log Analytics | Required | Recommended | Troubleshooting | Yes (vm module boot_diagnostics_enabled, boot_diagnostics_storage_uri; optional via tfvars) | — |
| Operational Excellence | Mandatory | VM insights / diagnostic extension to Log Analytics | Required | Recommended | Monitoring | No | Add VM insights extension or diagnostic setting in module |
| Operational Excellence | Mandatory | OS and patch baseline (image or automation) | Required | Recommended | Compliance | Partial (image ref in module) | Use consistent image SKU; patch via automation outside Terraform |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to vm module) | — |
| Governance | Mandatory | Naming convention (vm-&lt;org&gt;-&lt;os&gt;-&lt;role&gt;-&lt;env&gt;) | Required | Required | Consistency | Env (tfvars) | — |
| Cost Optimization | Optional | Right-size VM SKU; use reserved capacity in prod | Recommended | Optional | Cost | Env (tfvars) | — |

---

## Storage Account

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Reliability | Mandatory | Redundancy | GZRS / ZRS | LRS | High availability, durability | Yes (storage module replication_type; tfvars) | — |
| Reliability | Mandatory | Blob soft delete | 30 days | 7 days | Recovery from deletion | Yes (storage module blob_soft_delete_retention_days; optional via tfvars) | — |
| Reliability | Mandatory | Container soft delete | 30 days | 7 days | Recovery | Yes (storage module container_soft_delete_retention_days; optional via tfvars) | — |
| Reliability | Optional | Failover (GRS/GZRS) tested periodically | Recommended | Optional | DR readiness | No | Manual or runbook; not in Terraform |
| Security | Mandatory | Public access disabled (allow_blob_public_access = false) | Disabled | Disabled | Prevent anonymous access | Yes (storage module) | — |
| Security | Mandatory | Private endpoint for blob, file, queue, table as needed | Required | Recommended | Secure access | Yes (private_endpoints + private DNS in env) | — |
| Security | Mandatory | TLS 1.2+ minimum | Required | Required | Secure transport | Yes (storage module min_tls_version) | — |
| Security | Mandatory | HTTPS only | Required | Required | Secure transport | Yes (storage module) | — |
| Security | Mandatory | Shared Key auth disabled when using AAD only | Recommended | Optional | Prefer identity | Partial (variable in module; provider may not expose attribute; use Portal/Policy) | Set shared_key_access_disabled in tfvars; enable via Azure Portal/Policy if provider unsupported |
| Security | Optional | Customer-managed key (CMK) for encryption at rest | Required | Recommended | Compliance, key control | No | Add identity + key_vault_key_id in storage module |
| Security | Optional | Network rules: deny by default, allow selected nets only | Required | Recommended | Restrict access | Yes (storage module network_rules; optional via tfvars) | — |
| Security | Mandatory | Blob versioning for critical containers | Required | Recommended | Recovery, compliance | Yes (storage module enable_blob_versioning) | — |
| Operational Excellence | Mandatory | Diagnostic logs (storage logs) to Log Analytics | Required | Required | Audit trail | No | Add azurerm_monitor_diagnostic_setting for storage account |
| Operational Excellence | Mandatory | Metrics and alerts (availability, latency) | Required | Recommended | Monitoring | No | Add alert rules in Terraform or portal |
| Governance | Mandatory | Delete lock | Required | Optional | Prevent deletion | Yes (storage module create_delete_lock; optional via tfvars) | — |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Governance | Mandatory | Naming: no hyphens, globally unique, max 24 chars | Required | Required | Azure constraint | Env (tfvars) | — |
| Cost Optimization | Optional | Lifecycle management (tier to cool/archive) | Required | Recommended | Optimize storage cost | No | Configure in portal or add storage management policy in Terraform |
| Cost Optimization | Optional | Delete old versions after retention | Recommended | Optional | Cost | No | Lifecycle policy or manual |
| Cost Optimization | Optional | Access tier (hot/cool) per container | Recommended | Recommended | Cost | Partial (container config) | Add default_blob_access_tier or per-container tier in module if needed |

---

## Key Vault

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Public network access disabled | Disabled | Disabled | Prevent exposure | Yes (keyvault module public_network_access_enabled = false) | — |
| Security | Mandatory | Private endpoint | Required | Recommended | Secure access | Yes (private_endpoints + private DNS in env) | — |
| Security | Mandatory | RBAC only (no access policies) | Required | Required | Least privilege, audit | Yes (keyvault module rbac_authorization_enabled) | — |
| Security | Mandatory | Soft delete enabled | Required | Required | Recovery | Yes (keyvault module soft_delete_retention_days) | — |
| Security | Mandatory | Purge protection enabled | Required | Recommended | Prevent permanent loss | Yes (keyvault module purge_protection_enabled) | — |
| Security | Mandatory | Minimum TLS 1.2 (Azure default) | Required | Required | Secure transport | Partial (Azure default) | — |
| Security | Mandatory | Firewall / network rules when not using PE only | Required | Recommended | Defense in depth | Yes (keyvault module network_acls; optional via tfvars) | — |
| Security | Optional | Customer-managed key for Key Vault (double encryption) | Optional | Optional | Compliance | No | Add key_vault_key_id in keyvault module if required |
| Security | Mandatory | Secret access only via RBAC (Key Vault Secrets User, etc.) | Required | Required | Least privilege | Yes (role assignment in main.tf) | — |
| Reliability | Mandatory | Soft delete retention | 90 days | 7–30 days | Recovery | Yes (variable + tfvars) | — |
| Operational Excellence | Mandatory | Diagnostic logs (audit, access) to Log Analytics | Required | Required | Audit trail | No | Add diagnostic setting for Key Vault to Log Analytics |
| Operational Excellence | Mandatory | Alert on secret access / policy changes | Required | Recommended | Security monitoring | No | Configure alerts in portal or Terraform |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Governance | Optional | Delete lock | Recommended | Optional | Prevent deletion | Yes (keyvault module create_delete_lock; optional via tfvars) | — |
| Governance | Mandatory | Naming: globally unique, 3–24 chars | Required | Required | Azure constraint | Env (tfvars) | — |
| Cost Optimization | Optional | Single Key Vault per app/env boundary | Recommended | Recommended | Cost, management | Env (design) | — |

---

## Key Vault Secrets (usage)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | No secret value in code or committed tfvars | Required | Required | Prevent leakage | Partial (doc + sensitive var; enforce via process) | Enforce in CI: reject commits with secret patterns; use TF_VAR_* only |
| Security | Mandatory | Inject via TF_VAR or Key Vault data source in Terraform | Required | Required | Secure pipeline | Yes (TF_VAR_* / sensitive variables; README) | — |
| Security | Mandatory | Rotate secrets on schedule (process) | Required | Recommended | Reduce exposure | No (process) | Define rotation runbook; use Key Vault rotation or automation |
| Security | Optional | Content type set for secrets | Recommended | Optional | Handling guidance | Yes (key-vault-secret module content_type) | — |
| Governance | Mandatory | Naming convention for secret names | Required | Recommended | Discoverability | Env (tfvars) | — |
| Governance | Optional | Expiration date on certificates | Required | Recommended | Compliance | No | Set expiration when storing certs in Key Vault (portal or API) |
| Operational Excellence | Mandatory | Document secret purpose (tag or naming) | Recommended | Optional | Audit | Partial (naming in tfvars) | Add description tag or naming convention in tfvars |

---

## Private Endpoint

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Private DNS zone group (auto DNS registration) | Required | Required | Reliable private resolution | Yes (private-endpoint module + private_dns_zone_id in env) | — |
| Security | Mandatory | Subnet with private endpoint network policies disabled | Required | Required | Azure requirement | Yes (vnet module PE subnet) | — |
| Security | Mandatory | Dedicated subnet or segment for PEs (no VM in same subnet) | Recommended | Recommended | Isolation | Env (tfvars subnet design) | — |
| Security | Optional | Application security group or NSG on PE subnet | Optional | Optional | Traffic filter | No | Associate NSG to PE subnet in tfvars if required |
| Governance | Mandatory | Naming convention (pe-&lt;resource&gt;-&lt;subresource&gt;) | Required | Required | Clarity | Env (private_endpoints map in tfvars) | — |
| Governance | Mandatory | One PE per resource + subresource (blob, file, etc.) as needed | Required | Required | Correct connectivity | Yes (private_endpoints map + subresource_name) | — |
| Operational Excellence | Mandatory | Document PE to resource mapping | Recommended | Optional | Troubleshooting | Partial (map keys + comments) | Add README or comment mapping target_key → resource name |

---

## Private DNS Zone

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Link only to intended VNets | Required | Required | No cross-tenant or unintended resolution | Yes (main.tf zone VNet links to env VNets) | — |
| Security | Mandatory | No public resolution (private zones only) | Required | Required | Azure default | Yes (private zones only) | — |
| Operational Excellence | Mandatory | One zone per privatelink FQDN type (e.g. blob, vault, sql) | Required | Required | Correct resolution | Yes (main.tf blob, vault, sql, mysql, redis, acr, webapp zones) | — |
| Operational Excellence | Optional | Auto-registration with private endpoint | Required | Required | Avoid manual A records | Yes (private_dns_zone_id passed to PE module) | — |
| Governance | Mandatory | Naming matches Azure privatelink FQDN | Required | Required | e.g. privatelink.blob.core.windows.net | Yes (main.tf zone names) | — |

---

## Bastion

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Standard SKU | Required | Required | Stable, supported | Yes (bastion module sku) | — |
| Security | Mandatory | Static public IP (Standard) | Required | Required | Stable egress | Yes (module uses Standard PIP) | — |
| Security | Optional | Disable copy-paste from browser if not needed | Recommended | Optional | Reduce data exfil risk | Yes (bastion module copy_paste_enabled, etc.) | — |
| Security | Optional | Disable file copy if not needed | Recommended | Optional | Reduce blast radius | Yes (file_copy_enabled) | — |
| Security | Optional | Disable tunneling (e.g. RDP/SSH tunnel) if not needed | Recommended | Optional | Reduce exposure | Yes (tunneling_enabled) | — |
| Reliability | Mandatory | Dedicated AzureBastionSubnet (/26 or larger) | Required | Required | Azure requirement | Env (tfvars AzureBastionSubnet) | — |
| Reliability | Optional | Scale units for availability | Required | Optional | HA | Yes (bastion module scale_units) | — |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for Bastion to Log Analytics |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |

---

## SQL Server (Azure SQL Database)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Minimum TLS 1.2 | Required | Required | Secure transport | Yes (sql module min_tls_version) | — |
| Security | Mandatory | Firewall: restrict to app subnet / VNet / PE only | Required | Recommended | No 0.0.0.0/0 | Yes (sql module firewall_rules; tfvars) | — |
| Security | Mandatory | Private endpoint | Required | Recommended | Secure access | Yes (private_endpoints + DNS in env) | — |
| Security | Mandatory | Admin password via Key Vault or TF_VAR only | Required | Required | No secrets in code | Yes (sensitive variable; README) | — |
| Security | Mandatory | Azure AD admin configured for identity-based access | Required | Recommended | MFA, audit | Yes (sql module azuread_administrator; optional via tfvars) | — |
| Security | Optional | Transparent Data Encryption (TDE) with customer key | Required | Recommended | Key control | No | Add TDE with key_vault_key_id in database config |
| Security | Optional | Auditing to storage or Log Analytics | Required | Recommended | Compliance | Partial (variable in module; use azurerm_mssql_server_extended_auditing_policy resource) | Configure auditing via separate resource in env |
| Reliability | Mandatory | Database backup (PITR) with retention per policy | Required | Recommended | Recovery | Partial (Azure default; configurable via short_term_retention_days) | Set short_term_retention_days in databases in tfvars |
| Reliability | Mandatory | Short-term retention 7–35 days per policy | Required | 7 days | Recovery | Yes (sql module databases.short_term_retention_days; optional via tfvars) | — |
| Reliability | Optional | Long-term retention (LTR) | Required | Optional | Compliance | No | Configure LTR in portal or separate Terraform |
| Reliability | Optional | Zone redundancy / failover group | Required | Optional | HA | No | Add zone_redundant or failover group in module |
| Operational Excellence | Mandatory | Diagnostic logs (SQL insights, metrics) to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for SQL server to Log Analytics |
| Governance | Mandatory | Mandatory tags on server and databases | Required | Required | Audit | Yes (tags passed to sql module) | — |
| Governance | Mandatory | Naming convention | Required | Required | Consistency | Env (tfvars) | — |
| Cost Optimization | Optional | Right-size DTU/vCore; reserved capacity in prod | Recommended | Optional | Cost | Env (tfvars) | — |

---

## MySQL Flexible Server

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Firewall: restrict to app subnet or private access only | Required | Recommended | No open access | Yes (mysql module firewall_rules) | — |
| Security | Mandatory | Private endpoint / private access | Required | Recommended | Secure access | Yes (private_endpoints + DNS in env) | — |
| Security | Mandatory | Admin password via Key Vault or TF_VAR only | Required | Required | No secrets in code | Yes (sensitive variable; README) | — |
| Security | Optional | TLS 1.2 enforced | Required | Required | Secure transport | Partial (Azure default / config) | Set tls_version in mysql module if supported |
| Reliability | Mandatory | Backup retention | 7+ days (per policy) | 7 days | Recovery | Yes (mysql module backup_retention_days) | — |
| Reliability | Optional | Geo-redundant backup | Required | Optional | DR | No | Add geo_redundant_backup_enabled in mysql module |
| Reliability | Optional | High availability (same zone or zone redundant) | Required | Optional | HA | No | Add high_availability block in mysql module |
| Reliability | Optional | Storage auto-grow enabled | Required | Recommended | Avoid fill-up | No | Add storage_auto_grow in mysql module |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for MySQL to Log Analytics |
| Operational Excellence | Optional | Maintenance window configured | Required | Recommended | Predictability | No | Add maintenance_window in mysql module |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Governance | Mandatory | Naming convention | Required | Required | Consistency | Env (tfvars) | — |
| Cost Optimization | Optional | Right-size SKU; burstable for dev | Recommended | Recommended | Cost | Env (tfvars) | — |

---

## Redis Cache

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Non-SSL port (6379) disabled | Required | Required | Encrypt in transit | Yes (redis module non_ssl_port_enabled = false) | — |
| Security | Mandatory | Minimum TLS 1.2 | Required | Required | Secure transport | Yes (redis module minimum_tls_version) | — |
| Security | Mandatory | Private endpoint | Required | Recommended | Secure access | Yes (private_endpoints + DNS in env) | — |
| Security | Optional | Redis AUTH (password) rotated via Key Vault | Required | Recommended | Secret management | No | Use Key Vault reference for Redis auth; rotate via automation |
| Security | Mandatory | No firewall 0.0.0.0/0 when not using PE | Required | Recommended | Restrict access | Partial (env; no firewall in module) | Add redis_firewall_rules in tfvars; restrict to VNet/subnet |
| Reliability | Mandatory | Standard or Premium for replication in prod | Required | Optional | Replication, SLA | Yes (redis module sku_name; tfvars) | — |
| Reliability | Optional | Cluster (Premium) for HA | Required | Optional | HA | No | Use Premium SKU + cluster_enabled in redis module |
| Reliability | Optional | Patch schedule (maintenance window) | Required | Recommended | Predictability | No | Add maintenance_window in redis module if supported |
| Operational Excellence | Mandatory | Diagnostic logs (metrics) to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for Redis to Log Analytics |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Optional | Right-size capacity; reserved capacity in prod | Recommended | Optional | Cost | Env (tfvars) | — |

---

## App Service (Web App)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | FTPS disabled | Required | Required | Prefer secure channels | Yes (app-service module ftps_state) | — |
| Security | Mandatory | HTTPS only | Required | Required | Secure transport | Yes (app-service module https_only; default true, optional via tfvars) | — |
| Security | Mandatory | Private endpoint | Required | Recommended | Secure access | Yes (private_endpoints + DNS in env) | — |
| Security | Mandatory | Connection strings and app settings from Key Vault reference | Required | Required | No secrets in config | Partial (app_settings variable; use KV ref in tfvars) | Use @Microsoft.KeyVault(SecretUri=...) in app_settings in prod tfvars |
| Security | Mandatory | Managed identity for Azure resource access | Required | Required | No keys in config | Yes (app-service module identity_enabled; default true, optional via tfvars) | — |
| Security | Optional | Incoming client certs (mutual TLS) if required | Optional | Optional | Strong auth | Partial (app-service module client_certificate_enabled; provider support may vary) | Set in tfvars when provider supports site_config.client_certificate_mode |
| Security | Optional | Access restriction (IP/VNet) | Required | Recommended | Restrict access | No | Add ip_restriction / scm_ip_restriction in app-service module |
| Reliability | Mandatory | Always On (when not Free tier) | Required | Optional | Availability | Yes (app-service module always_on; optional via tfvars, overrides SKU default) | — |
| Reliability | Mandatory | Minimum instance count ≥ 2 for prod | Required | Optional | HA | No | Add site_config with minimum_elastic_instance_count or scale out in tfvars |
| Reliability | Optional | Deployment slot for blue-green | Required | Recommended | Zero-downtime deploy | No | Add slot in app-service module or separate resource |
| Operational Excellence | Mandatory | Diagnostic logs (app, web server) to Log Analytics | Required | Required | Audit trail | No | Add diagnostic setting for App Service to Log Analytics |
| Operational Excellence | Mandatory | Application Insights enabled | Required | Recommended | APM | No | Link app_insights_instrumentation_key in app_settings |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Mandatory | SKU: Premium v3 or higher for VNet integration / slots in prod | Required | Optional | Features, SLA | Yes (app_service module sku_name; tfvars) | — |

---

## Function App

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | FTPS disabled | Required | Required | Secure channels | Yes (function-app module) | — |
| Security | Mandatory | Storage key via Key Vault reference in prod | Required | Recommended | No secrets in config | Partial (app_settings; use KV ref in tfvars) | Set WEBSITE_RUN_FROM_PACKAGE or use Key Vault ref for storage in app_settings |
| Security | Mandatory | Private endpoint | Required | Recommended | Secure access | Yes (private_endpoints + DNS in env) | — |
| Security | Mandatory | Managed identity for triggers and bindings where supported | Required | Recommended | No keys in config | Partial (Azure default) | Assign RBAC for storage/queues to identity |
| Security | Optional | Access restriction (IP/VNet) | Required | Recommended | Restrict access | No | Add ip_restriction in function-app module |
| Reliability | Mandatory | Dedicated (Premium) or App Service Plan for prod SLA | Required | Optional | SLA, VNet integration | Yes (sku_name in tfvars) | — |
| Reliability | Optional | Minimum instance count for Premium | Required | Optional | Cold start, HA | No | Set minimum_elastic_instance_count in module if supported |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for Function App to Log Analytics |
| Operational Excellence | Mandatory | Application Insights enabled | Required | Recommended | APM | No | Add APPINSIGHTS_INSTRUMENTATIONKEY via app_settings |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Optional | Consumption (Y1) for dev; Premium for prod | Recommended | Recommended | Cost vs features | Env (tfvars sku_name) | — |

---

## Logic App

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Storage (workflow state) key via Key Vault reference | Required | Recommended | No secrets in config | Partial (storage from module; KV ref in app_settings) | Use Key Vault reference for storage key in logic_app app_settings |
| Security | Mandatory | Managed identity for connections where supported | Required | Recommended | No credentials in definition | Partial (Azure default) | Use managed identity in Logic App connections (portal or ARM) |
| Security | Optional | Private endpoint (Standard Logic App) | Required | Recommended | Secure access | Yes (private_endpoints for app_service type) | — |
| Reliability | Mandatory | Standard SKU (not Consumption) for VNet when required | Required | Optional | Connectivity | Yes (uses app service plan from app_services) | — |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for Logic App to Log Analytics |
| Operational Excellence | Optional | Run history retention | Required | Recommended | Troubleshooting | No | Set in Logic App config or app_settings |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |

---

## API Management (APIM)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | System-assigned managed identity | Required | Required | Backend / Key Vault auth | Yes (api-management module identity) | — |
| Security | Mandatory | VNet integration (internal or external) | Required | Recommended | Secure exposure | Yes (api_managements vnet_key, subnet_key; subnet_id in module) | — |
| Security | Optional | Disable HTTP/2 if not required | Recommended | Optional | Reduce surface | No | Add protocol block or disable_http2 in apim module if supported |
| Security | Mandatory | TLS 1.2+ for custom domains | Required | Required | Secure transport | Partial (Azure default) | — |
| Security | Optional | Client certificate authentication for backends | Optional | Optional | Mutual TLS | No | Configure in APIM backend; not in base module |
| Reliability | Mandatory | SKU Standard or higher for prod SLA | Required | Developer OK for non-prod | SLA, scale | Yes (api_managements sku_name; tfvars) | — |
| Reliability | Optional | Multiple scale units / zones | Required | Optional | HA | No | Add scale block with multiple units in apim module |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Required | Audit trail | No | Add diagnostic setting for APIM to Log Analytics |
| Operational Excellence | Mandatory | Enable logging for APIs (payload optional) | Required | Recommended | Debug, audit | No | Configure in API policies / diagnostic |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Mandatory | SKU and scale units per load | Required | Developer for dev | Cost | Env (tfvars) | — |

---

## AKS (Azure Kubernetes Service)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Azure AD integration | Required | Recommended | Identity-based access | Yes (AKS default; enable_azure_rbac in module) | — |
| Security | Mandatory | Azure RBAC for Kubernetes (enable_azure_rbac) | Required | Recommended | RBAC, audit | Yes (aks module enable_azure_rbac) | — |
| Security | Mandatory | Network policy (e.g. Azure CNI with policy) | Required | Recommended | Micro-segmentation | Yes (aks module network_plugin) | — |
| Security | Mandatory | Private cluster (API server private) | Recommended | Optional | No public API | No | Add private_cluster_enabled = true in aks module |
| Security | Mandatory | Standard load balancer | Required | Required | Supported, features | Yes (aks module load_balancer_sku) | — |
| Security | Optional | OIDC issuer for workload identity | Required | Recommended | Pod identity | No | Add oidc_issuer_enabled in aks module |
| Security | Mandatory | No --admin credentials in automation | Required | Required | Prefer Azure AD | Partial (doc; use Azure AD) | Do not use --admin in scripts; document Azure AD only |
| Reliability | Mandatory | Multiple nodes (min 2) for system pool | Required | Optional | HA | Yes (default_node_pool_node_count in tfvars) | — |
| Reliability | Mandatory | Node pool in dedicated subnet | Required | Required | Network isolation | Yes (vnet_subnet_id from tfvars) | — |
| Reliability | Optional | Availability zones for node pool | Required | Optional | HA | No | Add availability_zones in default node pool in aks module |
| Reliability | Optional | Multiple node pools (system + user) | Required | Recommended | Isolation | Yes (aks module user_node_pools) | — |
| Operational Excellence | Mandatory | Diagnostic logs (control plane) to Log Analytics | Required | Required | Audit trail | No | Add oms_agent / monitoring to Log Analytics in aks module |
| Operational Excellence | Mandatory | Container insights / monitoring | Required | Recommended | Observability | No | Enable container insights in AKS or add addon |
| Governance | Mandatory | Mandatory tags on cluster and node pools | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Optional | Node pool SKU and autoscale; spot for non-critical | Recommended | Optional | Cost | Yes (default_node_pool_vm_size, auto_scaling in module/tfvars) | — |

---

## Container Registry (ACR)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Admin user disabled | Required | Required | Use managed identity / AAD | Yes (registry module admin_enabled) | — |
| Security | Mandatory | Public network access disabled when using PE | Required | Recommended | Secure access | Yes (registry module public_network_access_enabled) | — |
| Security | Mandatory | Private endpoint | Required | Recommended | Secure access | Yes (private_endpoints + DNS in env) | — |
| Security | Mandatory | TLS 1.2+ (Azure default) | Required | Required | Secure transport | Partial (Azure default) | — |
| Security | Optional | Content trust (image signing) | Recommended | Optional | Supply chain | No | Enable in ACR portal or add policy in Terraform |
| Security | Optional | Vulnerability scanning (e.g. Defender for CR) | Required | Recommended | Image hygiene | No | Enable Defender for Containers / image scanning |
| Reliability | Optional | Geo-replication (Premium) for DR / latency | Required | Optional | DR, latency | No | Use Premium SKU + geo_replications in registry module |
| Reliability | Mandatory | Soft delete for images (retention) | Required | Recommended | Recovery | No | Enable in ACR; retention policy in portal or API |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for ACR to Log Analytics |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Governance | Mandatory | Naming: alphanumeric only, 5–50 chars, globally unique | Required | Required | Azure constraint | Env (tfvars) | — |
| Cost Optimization | Optional | SKU: Basic for dev, Standard/Premium for prod | Recommended | Recommended | Cost vs features | Yes (registry module sku; tfvars) | — |

---

## Log Analytics Workspace

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | No sensitive data in log content (PII, secrets) | Required | Required | Prevent leakage | No (process) | Define log exclusion/filtering in pipeline; avoid logging secrets |
| Security | Optional | Customer-managed key (CMK) for encryption | Required | Optional | Compliance | No | Add customer_managed_key in log-analytics module |
| Reliability | Mandatory | Retention | 90–365 days (per policy) | 30–90 days | Compliance, audit | Yes (log-analytics module retention_in_days) | — |
| Reliability | Optional | Commitment tier for predictable cost | Recommended | Optional | Capacity | No | Set commitment tier in LA workspace if needed |
| Operational Excellence | Mandatory | Central workspace per env or subscription | Required | Recommended | Single pane | Env (design) | — |
| Operational Excellence | Mandatory | Data source configuration (agents, diagnostics) | Required | Required | Ingestion | No | Link diagnostics from resources to workspace (diagnostic settings) |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Optional | Retention cap / archive to Storage | Recommended | Optional | Cost control | No | Configure in LA or use export rule |
| Cost Optimization | Optional | Daily cap to prevent runaway cost | Recommended | Recommended | Cost | No | Set daily_quota_gb in log-analytics module |

---

## Application Insights

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | No secrets in custom dimensions or properties | Required | Required | Prevent leakage | No (process) | Enforce in app code and review; do not log secrets |
| Security | Optional | Customer-managed key | Required | Optional | Compliance | No | Add customer-managed key in application-insights if supported |
| Operational Excellence | Mandatory | Link to Log Analytics workspace | Required | Recommended | Unified retention, query | Yes (application-insights module workspace_id) | — |
| Operational Excellence | Mandatory | Sampling / daily cap configured | Required | Recommended | Cost, volume | No | Set sampling_percentage / daily_cap in module or portal |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Optional | Sampling rate (e.g. 10% for high volume) | Recommended | Optional | Cost control | No | Add sampling in application_insights resource |
| Cost Optimization | Optional | Retention in App Insights vs workspace | Recommended | Recommended | Cost | No | Set retention_in_days in module |

---

## Managed Identity (User-Assigned)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Least privilege: only required roles (e.g. Key Vault Secrets User) | Required | Required | Minimize blast radius | No (assign roles outside module) | Add azurerm_role_assignment for identity in main.tf with minimal role |
| Security | Mandatory | One identity per app/workload boundary | Required | Recommended | Isolation | Env (managed_identities map) | — |
| Security | Optional | No shared identity across prod and non-prod | Required | Required | Boundary | Env (design) | — |
| Governance | Mandatory | Naming convention, mandatory tags | Required | Required | Audit | Yes (managed-identity module + tags) | — |
| Governance | Mandatory | Document role assignments | Recommended | Recommended | Audit | No | Document in README or add comments for each role assignment |

---

## NAT Gateway

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Stable outbound IP for allow-listing (e.g. SaaS) | Required | Recommended | Egress control | Yes (nat-gateway module + Standard PIP) | — |
| Reliability | Mandatory | Standard SKU public IP, static allocation | Required | Required | Stability | Yes (module) | — |
| Operational Excellence | Optional | Idle timeout configured (e.g. 4–120 min) | Recommended | Optional | Connection cleanup | Yes (nat-gateway module idle_timeout_in_minutes) | — |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Cost Optimization | Optional | Shared NAT for multiple subnets in same VNet | Recommended | Recommended | Cost | Env (subnet association) | — |

---

## Recovery Services Vault

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Soft delete enabled for backup items | Required | Required | Recovery | Yes (recovery-services module soft_delete_enabled) | — |
| Security | Mandatory | RBAC for backup operators (Backup Contributor, etc.) | Required | Required | Least privilege | No | Add role assignments for backup operators in main.tf |
| Security | Optional | Immutability (immutable vault) where supported | Recommended | Optional | Ransomware protection | No | Enable immutable vault in portal or Terraform if supported |
| Reliability | Mandatory | Backup policy retention per compliance (e.g. 7–30 years) | Required | Recommended | Recovery | No (policy separate) | Create backup policy with required retention via Terraform or portal |
| Reliability | Mandatory | Replication (GRS) for vault where required | Required | Optional | DR | No | Set cross_region_restore / storage_mode in module |
| Operational Excellence | Mandatory | Diagnostic logs to Log Analytics | Required | Recommended | Audit trail | No | Add diagnostic setting for RSV to Log Analytics |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed to module) | — |
| Governance | Optional | Delete lock | Recommended | Optional | Prevent deletion | Yes (recovery-services module create_delete_lock; optional via tfvars) | — |

---

## Terraform State (Backend Storage)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Remote backend (azurerm) | Required | Required | No local state with secrets | Partial (backend.tf present; commented for local in prod) | Uncomment backend in prod backend.tf; run init -reconfigure with -backend-config |
| Security | Mandatory | State storage: HTTPS only, TLS 1.2+ | Required | Required | Secure transport | Yes (Azure default) | — |
| Security | Mandatory | Restrict access (RBAC) to CI / service principal only | Required | Recommended | Least privilege | No (configure outside repo) | Grant Storage Blob Data Contributor only to CI SP on state container |
| Security | Optional | Private endpoint for state storage account | Recommended | Optional | No public access | No | Create PE for state storage account; use private DNS |
| Security | Mandatory | No state file in repo or artifact | Required | Required | Prevent leakage | Partial (.gitignore / process) | Ensure .gitignore has terraform.tfstate*; no state in artifacts |
| Reliability | Mandatory | Backend storage redundancy | GZRS/ZRS | LRS | Durability | No (backend config) | Create state storage account with GZRS; pass in -backend-config |
| Governance | Mandatory | Separate state key per environment | Required | Required | No cross-env drift | Yes (backend.tf key = prod.terraform.tfstate etc.) | — |
| Governance | Optional | Backend storage delete lock | Recommended | Optional | Prevent deletion | No | Add management lock on state storage account |

---

## RBAC (Role Assignments)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Least privilege: minimum roles per identity | Required | Required | Minimize blast radius | Partial (KV Secrets Officer, VM Admin Login in main.tf) | Add only required role assignments; avoid Contributor at scope above RG |
| Security | Mandatory | Prefer managed identity over service principal with secret | Required | Recommended | No secret rotation | Env (design) | — |
| Governance | Mandatory | Document role assignments (e.g. in code or runbook) | Required | Recommended | Audit | Partial (in main.tf) | Add comments for each role assignment; maintain runbook |
| Governance | Mandatory | No subscription Owner for automation; use custom or built-in minimal | Required | Required | Least privilege | No (process) | Use SP with minimal scope (e.g. RG or subscription Contributor); never Owner |
| Operational Excellence | Mandatory | Review role assignments periodically | Required | Recommended | Compliance | No | Schedule periodic review; use Azure Policy or script |

---

## Public IP (standalone, e.g. VM, NAT, Bastion)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Standard SKU only | Required | Required | Supported, features | Yes (vm, bastion, nat-gateway modules) | — |
| Security | Mandatory | Static allocation | Required | Required | Stable allow-listing | Yes (vm module allocation_method = Static) | — |
| Governance | Mandatory | Mandatory tags | Required | Required | Audit | Yes (tags passed via modules) | — |
| Cost Optimization | Optional | Release unused public IPs | Recommended | Recommended | Cost | Env (create_public_ip = false where not needed) | — |

---

## Network Security Group (NSG)

| Pillar | Type | Control | Prod | Non-Prod | Reason | Implemented | Remarks |
|--------|------|---------|------|-----------|--------|-------------|--------|
| Security | Mandatory | Deny-all inbound default (Azure default); explicit allow | Required | Required | Least privilege | Yes (vnet module nsg_rules = explicit allow only) | — |
| Security | Mandatory | No 0.0.0.0/0 for management (22, 3389) in prod | Required | Recommended | Limit exposure | Partial (env: jump_rdp_source_cidr, jump_ssh_source_cidr; prod.tfvars guidance) | Set jump_rdp_source_cidr / jump_ssh_source_cidr to VPN/bastion CIDR in prod; never * |
| Security | Mandatory | Restrict source/destination to smallest CIDR | Required | Recommended | Micro-segmentation | Partial (env-defined nsg_rules in tfvars) | Define nsg_rules with specific source_address_prefix (e.g. app subnet CIDR) |
| Operational Excellence | Mandatory | NSG flow logs to Log Analytics | Required | Recommended | Audit, troubleshooting | No | Add azurerm_network_watcher_flow_log for each NSG to Log Analytics |
| Governance | Mandatory | Naming convention, mandatory tags | Required | Required | Audit | Yes (tags on NSG via vnet module) | — |

---

*Use this sheet to align Prod and Non-Prod with enterprise baseline. **Implemented** = in modules or env (dev/prod): **Yes** / **Partial** / **No** / **Env**. **Remarks** = what is required to implement the control if not done (— when already done). Update when new resources or controls are added.*
