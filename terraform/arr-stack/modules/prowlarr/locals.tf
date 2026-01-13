locals {

  mapped_downloader_categories = {
    # See category IDs: https://github.com/Jackett/Jackett/blob/81f6899b0d3655/src/Jackett.Common/Models/TorznabCatType.cs
    audiobooks = toset([3030])
    movies     = toset([2000])
    tv         = toset([5000])
  }

  custom_mapped_downloader_categories = [
    for name, categories in local.mapped_downloader_categories :
    { name = name, categories = categories }
  ]
}
