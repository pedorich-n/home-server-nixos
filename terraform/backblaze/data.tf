data "b2_account_info" "info" {

}

data "corefunc_url_parse" "s3_base_url" {
  url = data.b2_account_info.info.s3_api_url
}
