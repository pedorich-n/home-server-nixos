locals {
  cf_account_id  = module.onepassword.secrets.Cloudflare.Account.id
  cf_zone_domain = module.onepassword.secrets.Cloudflare.Zone_Main.domain

  purelymail_subdomain = "mail"

  # From https://purelymail.com/docs/domainDocs#dnsrecords
  purelymail_records = {
    mx = {
      name     = local.purelymail_subdomain
      type     = "MX"
      content  = "mailserver.purelymail.com"
      priority = 50
    }

    spf = {
      name    = local.purelymail_subdomain
      type    = "TXT"
      content = "\"v=spf1 include:_spf.purelymail.com ~all\""
      # Cloudflare UI insists TXT records have to be wrapped in quotes
    }

    ownership = {
      name    = local.purelymail_subdomain
      type    = "TXT"
      content = "\"purelymail_ownership_proof=${module.onepassword.secrets.Purelymail.Domain.ownership_proof}\""
      # Cloudflare UI insists TXT records have to be wrapped in quotes
    }

    dkim_1 = {
      name    = "purelymail1._domainkey.${local.purelymail_subdomain}"
      type    = "CNAME"
      content = "key1.dkimroot.purelymail.com"
    }

    dkim_2 = {
      name    = "purelymail2._domainkey.${local.purelymail_subdomain}"
      type    = "CNAME"
      content = "key2.dkimroot.purelymail.com"
    }

    dkim_3 = {
      name    = "purelymail3._domainkey.${local.purelymail_subdomain}"
      type    = "CNAME"
      content = "key3.dkimroot.purelymail.com"
    }

    dmarc = {
      name    = "_dmarc.${local.purelymail_subdomain}"
      type    = "CNAME"
      content = "dmarcroot.purelymail.com"
    }
  }

  telegram_subnets = [
    # From https://core.telegram.org/bots/webhooks#the-short-version
    "149.154.160.0/20",
    "91.108.4.0/22"
  ]

  n8n_local_domain = "n8n.${local.cf_zone_domain}"
}
