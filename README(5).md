# Destructive vs Non‑Destructive Changes for `terraform-azurerm-avm-res-dbformysql-flexibleserver`

This table summarizes which configuration changes in the Azure MySQL
Flexible Server module cause **resource recreation (destructive)** and
which are **safe updates (non‑destructive)**.

------------------------------------------------------------------------

## **Destructive Changes (Cause Server Recreation)**

  --------------------------------------------------------------------------
  Setting / Attribute          Description          Why Destructive?
  ---------------------------- -------------------- ------------------------
  `name`                       Changing server name Server identity changes

  `location`                   Region change        Cross‑region move
                                                    requires rebuild

  `resource_group_name`        Changing RG          Server must be
                                                    re‑provisioned

  `administrator_login`        MySQL admin username Cannot be modified on
                                                    existing server

  `administrator_password` (in Azure may require    Sensitive admin
  some scenarios)              recreation depending properties
                               on module            
                               implementation       

  `sku_name` (major changes)   Moving between       Azure re‑creates on tier
                               compute tiers (e.g., changes
                               B_Standard →         
                               GP_Standard)         

  `storage.tier`               Changing storage     Requires underlying
                               tier                 storage recreation

  `high_availability.mode`     Changing SameZone ↔  Azure re‑provisions HA
  (enable/disable)             ZoneRedundant        architecture

  `backup.retention_days`      Reducing retention   Azure does not allow
  (decrease)                                        shrink in place

  `customer_managed_key` (CMK  Enabling/disabling   Encryption state cannot
  enable/disable)              encryption           be modified without
                                                    recreation
  --------------------------------------------------------------------------

------------------------------------------------------------------------

## **Non‑Destructive Changes (Safe Updates)**

  ------------------------------------------------------------------------------------
  Setting / Attribute                           Description          Why Safe?
  --------------------------------------------- -------------------- -----------------
  `tags`                                        Modify tags          Metadata update
                                                                     only

  `sku_name` (minor change)                     CPU/Memory size      Azure performs
                                                changes within same  in‑place resize
                                                family               

  `storage.size_gb`                             Increasing storage   Azure supports
                                                                     online expansion

  `backup.retention_days` (increase)            Increasing backup    Non‑breaking
                                                retention            

  `maintenance_window`                          Changing maintenance No downtime
                                                window               recreation

  `data_encryption.key_vault_key_id`            Rotating CMK keys    Key rotation
                                                                     supported

  `auth_config.active_directory_auth_enabled`   Toggle Entra auth    In‑place update

  `connection_audit` flags                      Audit settings       Non‑destructive
  ------------------------------------------------------------------------------------

------------------------------------------------------------------------

## **Notes**

-   Azure MySQL Flexible Server has strict limitations on username, HA,
    and encryption settings.
-   Terraform detects many of these settings as **ForceNew**, causing
    recreation.
-   Always run `terraform plan` before applying changes in production.

------------------------------------------------------------------------

Generated based on the behavior of the Azure MySQL Flexible Server
resource and the module implementation.
