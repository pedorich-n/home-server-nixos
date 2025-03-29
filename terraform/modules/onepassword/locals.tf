locals {
  secrets = {
    for key, item in data.onepassword_item.items : key => {
      for section in item.section : section.label => {
        for field in section.field : field.label => field.value
      }
    }
  }
}
