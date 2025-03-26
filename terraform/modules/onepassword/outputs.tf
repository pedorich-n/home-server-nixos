output "vault_homelab" {
  value = data.onepassword_vault.homelab
}

output "secrets" {
  value     = local.secrets
  sensitive = true
}