module "onepassword" {
  source = "../modules/onepassword"
  items  = ["Cloudflare", "Cloudflare_Tunnels", "Purelymail"]
}