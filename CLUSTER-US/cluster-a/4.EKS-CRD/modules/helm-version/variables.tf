variable "chart_name" {
  type        = string
  description = "The name of the chart (key in the JSON file) to get the version for."
}

variable "versions_file_path" {
  type        = string
  description = "The absolute path to the JSON file containing chart versions."
}
