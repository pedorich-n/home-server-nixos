locals {
  purelymail_subdomain = "mail"

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
    }

    ownership = {
      name    = local.purelymail_subdomain
      type    = "TXT"
      content = "\"purelymail_ownership_proof=${module.onepassword.secrets.Purelymail.Domain.ownership_proof}\""
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
}
