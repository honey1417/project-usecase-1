resource "google_container_cluster" "primary" {
    name = var.GKE-CLUSTER 
    location = var.GKE-REGION
    initial_node_count = var.NODE-COUNT


    node_config {
        machine_type = var.MACHINE-TYPE 
        disk_size_gb = 30
        oath_scopes = [
            ""https://www.googleapis.com/auth/cloud-platform"
        ]
    }
}
output "kubeconfig" {
    value = google_container_cluster.primary.endpoint
}