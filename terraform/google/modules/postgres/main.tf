resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = var.network_name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}

resource "google_compute_global_address" "private_ip_range" {
  provider      = google-beta
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.network_name
}


resource "google_sql_database_instance" "postgres_instance" {
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  database_version = "POSTGRES_15"
  name             = "postgres-instance"
  project          = var.project_id
  region           = var.region

  settings {
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"

    backup_configuration {
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }

      enabled                        = true
      location                       = "eu"
      point_in_time_recovery_enabled = true
      start_time                     = "21:00"
      transaction_log_retention_days = 7
    }

    disk_autoresize       = true
    disk_autoresize_limit = 0
    disk_size             = 100
    disk_type             = "PD_SSD"

    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/${var.network_name}"
      # ssl_mode        = "ENCRYPTED_ONLY"  // enable this for extra security
    }

    location_preference {
      zone = "${var.region}-b"
    }

    maintenance_window {
      update_track = "canary"
      day          = 7
    }

    pricing_plan = "PER_USE"
    tier         = "db-custom-2-8192"
  }
}

resource "google_sql_user" "langfuse_user" {
  name     = var.env_postgres["POSTGRES_USER"]
  instance = google_sql_database_instance.postgres_instance.name
  project  = var.project_id
  password = var.env_postgres["POSTGRES_PASSWORD"]
}
